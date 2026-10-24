function test_filter_family()
%TEST_FILTER_FAMILY Numerical contracts for the layered filter API.
root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'path'));
rng(42); fs=500; t=(0:4999)'/fs;
x=[sin(2*pi*10*t)+.5*sin(2*pi*90*t), cos(2*pi*10*t)];

% Frequency generators: count/one/all agreement, endpoints and true overlap.
assert(filter_dyadic(fs,3,.5)==15);
b=filter_dyadic(fs,3,.5,'all'); assert(numel(b)==15);
assert(b(1).low==0 && b(end).high==fs/2);
assert(abs((b(1).high-b(2).low)/b(1).bandwidth-.5)<1e-14);
for k=1:numel(b), assert(isequal(b(k),filter_dyadic(fs,3,.5,k))); end
assert(strcmp(filter_dyadic_kind(fs),'identity'));
assert(filter_overlap(fs,7,.5)==70);
g=filter_logarithmic(fs,1,4,.5,'all');
assert(numel(g)==filter_logarithmic(fs,1,4,.5));
assert(all([g.low]>0) && all([g.high]<=fs/2));
assert(abs(log2(g(2).low/g(1).low)-.125)<1e-12);
must_error(@() filter_uniform(fs,3,1));
must_error(@() filter_dyadic(fs,2,0,5));
must_error(@() filter_logarithmic(fs,0,4,0));

% Chunk continuity, row preservation and coefficient-design variants.
designs={filter_butterworth(fs,[4 20],4),filter_chebyshev1(fs,[4 20],4), ...
    filter_chebyshev2(fs,[4 20],4),filter_elliptic(fs,[4 20],4), ...
    filter_windowed_fir(fs,[4 20],100), ...
    filter_equiripple_fir(fs,[4 20],100,'TransitionHz',2)};
for k=1:numel(designs)
    d=designs{k}; whole=filter_causal(x,d);
    s=filter_state(d,2);
    [a,s]=filter_causal(x(1:1234,:),d,s);
    [bb,s]=filter_causal(x(1235:end,:),d,s); %#ok<ASGLU>
    assert(max(abs(whole(:)-reshape([a;bb],[],1)))<1e-11);
    z=filter_forward_backward(x,d); assert(all(isfinite(z(:))));
    zr=filter_forward_backward(x(:,1)',d); assert(isrow(zr));
    assert(max(abs(zr'-z(:,1)))<1e-10);
end
d=designs{1}; z=filter_forward_backward(x,d); inner=501:4500;
slow=sin(2*pi*10*t); fast=sin(2*pi*90*t);
assert(abs(slow(inner)'*z(inner,1))>20*abs(fast(inner)'*z(inner,1)));
identity=filter_butterworth(fs,[0 fs/2],4);
assert(isequal(x,filter_forward_backward(x,identity)));
must_error(@() filter_causal(x(:,1),d,filter_state(d,2)));
for band={[0 20],[200 250]}
    di=filter_butterworth(fs,band{1},4); zz=filter_forward_backward(x,di);
    assert(all(isfinite(zz(:))));
end
[xp,keep]=filter_pad(x,20,'reflect'); assert(isequal(xp(keep,:),x));
assert(isequal(xp(1,:),x(21,:)));

% Artifact removal must suppress the injected line and preserve a clean tone.
line=2*cos(2*pi*60*t); contaminated=slow+line;
[clean,noise]=filter_line_regression(contaminated,fs,60);
assert(norm(clean-slow)/norm(slow)<1e-10);
assert(norm(noise-line)/norm(line)<1e-10);
clean=filter_spectrum_interpolation(contaminated,fs,[59 61]);
assert(norm(clean-slow)/norm(slow)<1e-10);
for n=[999 1000]
    xx=randn(n,2); yy=filter_spectrum_interpolation(xx,fs,[59 61]);
    assert(isequal(size(xx),size(yy)) && all(isfinite(yy(:))));
end
xx=(1:100)'; xx(48:52)=1000;
[yy,mask]=filter_despike(xx,50,2);
assert(max(abs(yy-(1:100)'))<1e-12 && sum(mask)==5);
must_error(@() filter_despike(xx,1,2));
base=2+3*linspace(-1,1,1000)'; xx=base; xx(500)=1e4;
[~,trend]=filter_robust_detrend(xx,1,50);
assert(norm(trend-base)/norm(base)<1e-5);

% Spatial invariants, physical units and generalized eigensystem residuals.
xx=randn(1000,4); yy=filter_rereference(xx,'mean');
assert(max(abs(mean(yy,2)))<1e-12);
assert(isequal(filter_rereference(xx,'bipolar',[1 2]),xx(:,1)-xx(:,2)));
c0=diag([1 2 3]); c1=diag([9 4 3]);
[w,score]=filter_joint_decorrelation(c1,c0,0);
assert(norm(w'*c0*w-eye(3),'fro')<1e-12);
assert(norm(c1*w-c0*w*diag(score),'fro')<1e-12);
depth=[0 1 2 4 7]*1e-4;
[csd,zz]=filter_csd(repmat(depth.^2,10,1),depth,.3);
assert(max(abs(csd(:)+.6))<1e-12 && numel(zz)==3);
[yy,w,score,model]=filter_ssd(xx,filter_butterworth(fs,[8 12],3), ...
    {filter_butterworth(fs,[4 7],3),filter_butterworth(fs,[13 16],3)},1e-6);
assert(norm(yy-bsxfun(@minus,xx,model.mean)*w,'fro')<1e-10);
assert(all(diff(score)<=0));

% Fourier frequency axis and analytic representation identities.
[st,f,tt]=filter_stft(slow,fs,500,.5,500);
[~,peak]=max(abs(st(:,1))); assert(f(peak)==10);
assert(size(st,2)==numel(tt));
[p,f,tt]=filter_multitaper(slow,fs,1,.5,3,5);
assert(size(p,1)==numel(f) && size(p,2)==numel(tt));
z=filter_analytic(slow); assert(max(abs(filter_power(z)-1))<1e-10);
phi=filter_phase(z); assert(max(abs(exp(1i*phi)-z))<1e-10);
assert(isnan(filter_phase(0)));

% Optional backends: numerical reconstruction when available, explicit errors otherwise.
if exist('modwpt','file') && exist('wpdec','file')
    xx=sin(2*pi*(0:2047)'*20/fs);
    [d,meta]=filter_modwpt_details(xx,fs,3,'db4'); %#ok<ASGLU>
    assert(norm(sum(d,1)'-xx)/norm(xx)<1e-9);
    [c,meta]=filter_modwpt(xx,fs,3,'db4');
    assert(isequal(size(c),[8 numel(xx)]) && all(diff(meta.frequency_hz)>0));
    [c,meta,tr]=filter_wpt(xx,fs,3,'db4'); %#ok<ASGLU>
    reconstructed=zeros(size(xx));
    for k=1:8
        part=wprcoef(tr,[3 meta.node_position(k)]);
        reconstructed=reconstructed+part(:);
    end
    assert(norm(reconstructed-xx)/norm(xx)<1e-9);
    [c,f,coi]=filter_cwt(xx,fs,'morse');
    assert(size(c,2)==numel(xx) && size(c,1)==numel(f) && numel(coi)==numel(xx));
else
    fprintf('SKIP wavelet backend numerical tests: Wavelet Toolbox unavailable\n');
end
if exist('emd','file')
    [imf,r]=filter_emd(slow(1:1000),'MaxNumIMF',2);
    assert(norm(sum(imf,2)+r-slow(1:1000))<1e-8);
end
if ~exist('vmd','file')
    must_dependency(@() filter_vmd(slow));
else
    [imf,r]=filter_vmd(slow(1:1000),'NumIMFs',2);
    assert(norm(sum(imf,2)+r-slow(1:1000))<1e-6);
end
if ~exist('nt_zapline','file'), must_dependency(@() filter_zapline(xx,fs,60,1)); end

% Real/complex binary round trips, immutable destination and truncation detection.
folder=tempname; cleanup=onCleanup(@() remove_folder(folder));
metadata=struct('representation','complex_coefficients','units','uV', ...
    'source','synthetic','configuration',identity,'fs',fs);
value=reshape(complex(1:60,61:120),[10 3 2]);
m=filter_write(folder,value,metadata,'single');
assert(m.bytes==numel(value)*8);
readback=filter_read(folder,2:4,2,1);
assert(isequal(readback,single(value(2:4,2,1))));
must_error(@() filter_write(folder,value,metadata,'single'));
fid=fopen(fullfile(folder,'data.bin'),'w'); fclose(fid);
must_error(@() filter_open(folder));
clear cleanup
folder=tempname; cleanup=onCleanup(@() remove_folder(folder));
metadata.representation='voltage';
filter_write(folder,x,metadata,'double');
assert(isequal(filter_read(folder),x));
clear cleanup
fprintf('filter family numerical contracts passed\n');
end

function kind=filter_dyadic_kind(fs)
b=filter_dyadic(fs,0,0,1); kind=b.kind;
end
function must_error(f)
failed=false; try, f(); catch, failed=true; end
assert(failed,'Expected invalid input to fail');
end
function must_dependency(f)
failed=false;
try, f(); catch err, failed=strcmp(err.identifier,'neuronal:filter:Dependency'); end
assert(failed,'Expected explicit dependency error');
end
function remove_folder(folder)
if exist(folder,'dir'), rmdir(folder,'s'); end
end

function test_spike_interval_features
%TEST_SPIKE_INTERVAL_FEATURES Compare prefix reductions against direct masks.
rng(7); N=200; fs=20; units=4;
t=[0;.05;.05;1;2;9.999;10;NaN;-1;rand(90,1)*10];
u=[1;1;2;2;1;3;1;1;1;randi(3,90,1)];
bounds=[0 10;0 1;1 2;2 3;.05 1;8 10;4 4.01];
p=spike_interval_plan(t,u,units,N,fs,bounds);
assert(p.excluded_spikes==3);
h=complex(cos((1:N)'*.31),sin((1:N)'*.31)).*(1+(1:N)'/N);
h(12)=0; h(25)=NaN;
r=spike_interval_features(p,h,.2,0);
for unit=1:units
    for w=1:size(bounds,1)
        selected=isfinite(t)&t>=0&t<10&u==unit&t>=bounds(w,1)&t<bounds(w,2);
        assert(p.counts(w,unit)==sum(selected));
        ts=t(selected); sample=floor(ts*fs)+1;
        z=h(sample); a=abs(z);
        valid=isfinite(real(z))&isfinite(imag(z))&a>0&ts>=.2&ts<9.8;
        z=z(valid); a=a(valid);
        assert(r.phase_count(w,unit)==numel(z));
        if isempty(z)
            assert(isnan(r.phase_mean(w,unit))&&isnan(r.phase_strength(w,unit))&&isnan(r.amplitude_mean(w,unit)));
        else
            mean_z=mean(z./a);
            assert(abs(double(r.phase_strength(w,unit))-abs(mean_z))<1e-6);
            assert(abs(double(r.amplitude_mean(w,unit))-mean(a))<1e-6);
            if abs(mean_z)>1e-10
                delta=double(r.phase_mean(w,unit))-angle(mean_z);
                assert(abs(atan2(sin(delta),cos(delta)))<1e-6);
            end
        end
    end
end
% Circular wrap and undefined direction at exact cancellation.
p=spike_interval_plan([0;.1],[1;1],1,10,10,[0 1;0 .1;.1 1]);
h=ones(10,1); h(1:2)=exp(1i*[179;-179]*pi/180);
r=spike_interval_features(p,h,0,0);
assert(abs(abs(double(r.phase_mean(1)))-pi)<1e-6);
assert(isequal(p.counts,uint32([2;1;1])));
h(1:2)=[1;-1]; r=spike_interval_features(p,h,0,0);
assert(isnan(r.phase_mean(1)) && r.phase_strength(1)==0);
% No spikes, unordered/overlapping windows and empty units are valid.
p=spike_interval_plan([],[],3,10,10,[.5 1;0 .5;0 1]);
r=spike_interval_features(p,ones(10,1),0,0);
assert(all(p.counts(:)==0)&&all(r.phase_count(:)==0)&&all(isnan(r.phase_mean(:))));
% Actual multilevel generator shares the same half-open boundary contract.
w=interval_dyadic(N,fs,0:3,.5,'all'); bounds=[[w.t0]' [w.t1]'];
p=spike_interval_plan(t,u,units,N,fs,bounds);
for j=1:numel(w)
    for unit=1:units
        expected=sum(isfinite(t)&t>=0&t<N/fs&u==unit&t>=w(j).t0&t<w(j).t1);
        assert(p.counts(j,unit)==expected);
    end
end
% Filter/Hilbert/storage integration when Signal Processing Toolbox is present.
if license('test','Signal_Toolbox')
    N=1000; fs=100; signal=cos(2*pi*8*(0:N-1)'/fs);
    fd=filter_design('butterworth',fs,[6 10],4);
    h=hilbert(filter_do(signal,fs,fd,'phase','zero'));
    p=spike_interval_plan((1:.125:8)',ones(57,1),1,N,fs,[0 5;5 10]);
    r=spike_interval_features(p,h,1,0);
    assert(all(r.phase_count>0)&&all(r.phase_strength>.95));
    root=tempname; cleanup=onCleanup(@()remove(root)); %#ok<NASGU>
    st=storage_hdf5('root',root);
    storage_write(st,'phase',r.phase_mean);
    assert(isequaln(storage_read(st,'phase'),r.phase_mean));
else
    fprintf('SKIP filtering integration: Signal Processing Toolbox unavailable.\n');
end
fprintf('Spike interval plan/features contracts passed.\n');
end
function remove(root)
if isfolder(root), rmdir(root,'s'); end
end

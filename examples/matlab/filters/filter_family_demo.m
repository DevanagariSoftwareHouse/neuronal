%% Frequency geometry -> design -> application -> persistent artifact.
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(root,'matlab','path'));
fs=500; t=(0:fs*10-1)'/fs;
x=[sin(2*pi*10*t)+.3*sin(2*pi*90*t),cos(2*pi*10*t)];

n=filter_dyadic(fs,4,.5); % metadata only: no full bank allocation
band=filter_dyadic(fs,4,.5,2);
d=filter_butterworth(fs,[band.low band.high],4);
y=filter_forward_backward(x,d);
z=filter_analytic(y);
power=filter_power(z); phase=filter_phase(z);

% Causal chunk processing uses the same design and carries exact states.
[first,state]=filter_causal(x(1:1000,:),d);
[rest,state]=filter_causal(x(1001:end,:),d,state);
whole=filter_causal(x,d);
assert(max(abs(whole(:)-reshape([first;rest],[],1)))<1e-10);

% Temporary demonstration artifact; replace folder with a durable dataset path.
folder=tempname;
metadata=struct('representation','voltage','units','arbitrary', ...
    'source','synthetic demonstration','configuration',d,'fs',fs,'band',band);
filter_write(folder,y,metadata,'single');
[map,manifest]=filter_open(folder);
segment=map.Data.real(1:500,1);
fprintf('%d candidate intervals; artifact: %s\n',n,folder);
plot(t(1:500),segment); xlabel('Time (s)'); ylabel('Filtered voltage');
% For CON2PHYS channels-by-samples maps, select a channel then transpose:
% x=double(data(dd).lfp_1.Data.x(ch,:)).';
% Whole-record filtering needs this selected channel in RAM; mmap is for reuse.

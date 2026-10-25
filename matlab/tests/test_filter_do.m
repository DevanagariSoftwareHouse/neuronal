%TEST_FILTER_DO Smoke tests for FILTER_DESIGN + FILTER_DO.
fs=500;
t=(0:fs*4-1)'/fs;
x=sin(2*pi*10*t)+sin(2*pi*180*t);
fd=filter_design('butterworth',fs,[0 125],4);
y=filter_do(x,fs,fd);
assert(isequal(size(y),size(x)));
assert(all(isfinite(y)));
idx=(fs+1):numel(x);
probe=sin(2*pi*180*t(idx));
before=2*abs(mean(x(idx).*probe));
after=2*abs(mean(y(idx).*probe));
assert(after<before/5,'Expected high-frequency attenuation.');
z=filter_do(x,fs,filter_design('butterworth',fs,[0 fs/2],4));
assert(isequal(z,x),'Identity design must preserve input.');
fir=filter_design('windowed_fir',fs,[0 125],20);
yf=filter_do(x,fs,fir);
assert(isequal(size(yf),size(x)) && all(isfinite(yf)));
if gpuDeviceCount>0
    yg=filter_do(gpuArray(single(x)),fs,fd);
    assert(isa(yg,'gpuArray'));
    assert(max(abs(double(gather(yg))-y))<1e-3);
end
fprintf('filter_do smoke tests passed.\n');

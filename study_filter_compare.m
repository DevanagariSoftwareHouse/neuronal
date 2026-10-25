fs = 1000; t = (0:fs*2-1)'/fs;
x = sin(2*pi*80*t);
r = filter_compare(x, fs, [40 80 120], [4 6 8])
r
r(1)

%%
close all

rr = r(1)

figure('windowstyle','docked')
plot(rr.kernel_time,rr.kernel)

figure('windowstyle','docked')
plot(rr.time,rr.hilbert)

figure('windowstyle','docked'); 
plot(rr.frequency,rr.transfer)
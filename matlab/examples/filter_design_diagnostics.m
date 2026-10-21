%FILTER_DESIGN_DIAGNOSTICS Raw vs extracted frequency-domain behavior.
% Uses synthetic 8 Hz theta, 60 Hz interference and 120 Hz activity.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'path'));
fs = 1000;
t  = (0:fs*6-1)'/fs;
x  = sin(2*pi*8*t) + 0.4*sin(2*pi*60*t) ...
   + 0.3*sin(2*pi*120*t);

[theta, b] = fir_filter_lfp(x, fs, 'bandpass', [4 12], 200, 'kaiser');
r = filter_response(b,1,fs,4096,true);
[valid, margin] = filter_edge_mask(r.impulse,numel(x),1e-3);

figure('Name','Filter response and edge diagnostics');
subplot(3,1,1);
plot(r.frequency,r.attenuation_db); xlim([0 150]); ylim([-100 10]);
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('Idealized effective forward-backward filter response');
subplot(3,1,2);
plot(r.impulse_time,r.impulse);
xlabel('Time (s)'); title('Centered effective impulse response');
subplot(3,1,3);
plot(t,x,'Color',[0.65 0.65 0.65]); hold on;
plot(t,theta);
plot(t(~valid),theta(~valid),'.');
hold off;
xlabel('Time (s)');
title(sprintf('Raw vs filtered; excluded edge margin %d samples',margin));
legend('Original','Filtered','Edge exclusion');

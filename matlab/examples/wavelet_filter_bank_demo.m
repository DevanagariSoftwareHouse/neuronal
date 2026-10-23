%WAVELET_FILTER_BANK_DEMO Reproducible synthetic LFP with theta/gamma burst.
% Run from repository root or add matlab/path manually before running.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'path'));

rng(42);
fs = 500;
t  = (0:fs*12-1)' / fs;

theta = sin(2*pi*8*t);
burst = exp(-0.5*((t-6)/0.7).^2);
gamma = 0.8 * burst .* sin(2*pi*45*t);
lfp   = theta + gamma + 0.12*randn(size(t));

[bank, bands, labels] = filter_bank_lfp(lfp, fs);
[power, frequencies, time, ~, valid] = wavelet_spectrogram( ...
    lfp, fs, 2:2:90, 6);
power(~valid) = NaN;

figure('Name', 'Synthetic wavelet and filter-bank example');
subplot(3, 1, 1);
plot(t, lfp);
xlabel('Time (s)'); ylabel('Amplitude');
title('Synthetic LFP: theta with transient gamma');

subplot(3, 1, 2);
imagesc(time, frequencies, 10*log10(max(power, eps)));
axis xy;
xlabel('Time (s)'); ylabel('Frequency (Hz)');
title('Complex Morlet power (dB, arbitrary reference)');
colorbar;

subplot(3, 1, 3);
plot(t, bank(:, 1, strcmp(labels, 'theta')), ...
     t, bank(:, 1, strcmp(labels, 'low_gamma')));
xlabel('Time (s)'); ylabel('Filtered amplitude');
legend('Theta', 'Low gamma');
title('Zero-phase Butterworth filter bank');

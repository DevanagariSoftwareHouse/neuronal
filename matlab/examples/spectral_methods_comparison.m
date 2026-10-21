%SPECTRAL_METHODS_COMPARISON Compare three complementary estimators.
% Run this from any directory with matlab/path available or use this setup.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'path'));

rng(29);
fs = 500;
t  = (0:fs*12-1)'/fs;
theta = sin(2*pi*8*t);
burst = exp(-0.5*((t-6)/0.6).^2);
gamma = 0.8*burst.*sin(2*pi*42*t);
lfp = theta + gamma + 0.10*randn(size(t));

[pw, fw, tw] = welch_spectrogram(lfp, fs, 1, .75);
[pm, fm, tm] = multitaper_spectrogram(lfp, fs, 1, .75, 3, 5);
[pc, fc, tc, ~, valid] = wavelet_spectrogram( ...
    lfp, fs, 2:2:90, linspace(4, 9, 45));
pc(~valid) = NaN;

figure('Name', 'Spectral methods comparison');
subplot(4, 1, 1);
plot(t, lfp); xlim([0 12]); ylabel('LFP');
title('Synthetic 8 Hz oscillation with transient 42 Hz burst');

subplot(4, 1, 2);
imagesc(tw, fw, 10*log10(max(pw, eps)));
axis xy; ylim([0 90]); ylabel('Hz');
title('Hann sliding-window spectrogram (PSD/Hz)');
colorbar;

subplot(4, 1, 3);
imagesc(tm, fm, 10*log10(max(pm, eps)));
axis xy; ylim([0 90]); ylabel('Hz');
title('DPSS multitaper spectrogram (PSD/Hz)');
colorbar;

subplot(4, 1, 4);
imagesc(tc, fc, 10*log10(max(pc, eps)));
axis xy; ylabel('Hz'); xlabel('Time (s)');
title('Morlet spectrogram (wavelet energy, not PSD/Hz)');
colorbar;
% The two upper spectral plots share PSD units; Morlet uses another
% normalization. Do not interpret color magnitudes as directly comparable.

function [times_s,indices,threshold] = spike_threshold_detection(signal,srate,threshold_sigma,refractory_s)
%SPIKE_THRESHOLD_DETECTION Negative extracellular transient candidates.
% Only for broadband, sufficiently sampled data; not applicable to 500 Hz LFP.
% Does not perform sorting, drift correction or waveform artifact checks.
%
%   SYNTAX
%     [times_s,indices,threshold] = spike_threshold_detection(signal,srate,threshold_sigma,refractory_s)
%
%   INPUTS
%     signal: Finite real broadband high-rate extracellular voltage vector, with nonzero robust
%       noise scale.
%     srate: Positive waveform sampling rate in Hz, e.g. 30000 (not downsampled LFP).
%     threshold_sigma: Positive multiplier of median-based noise SD; default 4.
%     refractory_s: Positive minimum peak separation in seconds; default 0.001.
%
%   OUTPUTS
%     times_s: Column of detected negative-peak timestamps in seconds.
%     indices: Corresponding 1-based sample indices.
%     threshold: Positive amplitude threshold; applied to -signal.
%
%   Requires Signal Processing Toolbox (findpeaks).
%
%   EXAMPLE
%     rng(7); fs = 30000; x = 0.1*randn(30000,1); x([5000 15000]) = -2;
%     [times_s, indices, threshold] = spike_threshold_detection(x,fs,4,0.001);
%     % These are transient candidates, not sorted units.
%
if nargin<3 || isempty(threshold_sigma), threshold_sigma=4; end
if nargin<4 || isempty(refractory_s), refractory_s=.001; end
x=double(signal(:));
assert(all(isfinite(x)) && srate>0 && threshold_sigma>0 && refractory_s>0);
noise_sigma=median(abs(x-median(x)))/.67448975;
assert(noise_sigma>0,'Robust noise scale is zero');
threshold=threshold_sigma*noise_sigma;
[~,indices]=findpeaks(-x,'MinPeakHeight',threshold, ...
    'MinPeakDistance',max(1,round(refractory_s*srate)));
times_s=(indices-1)/srate;
end

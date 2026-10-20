function [times_s,indices,threshold] = spike_threshold_detection(signal,srate,threshold_sigma,refractory_s)
%SPIKE_THRESHOLD_DETECTION Negative extracellular transient candidates.
% Only for broadband, sufficiently sampled data; not applicable to 500 Hz LFP.
% Does not perform sorting, drift correction or waveform artifact checks.
%
%   SIGNATURE DESCRIPTION
%     signal — sampled signal; units and sample axis are given in the notes above.
%     srate — sampling rate in Hz.
%     threshold_sigma — the threshold sigma value; expected shape, units, and constraints are stated in the notes above.
%     refractory_s — the refractory s value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     times_s — event timestamps in seconds.
%     indices — the returned value; see the summary above for meaning and units.
%     threshold — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [times_s, indices, threshold] = spike_threshold_detection(signal, srate, threshold_sigma, refractory_s);
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

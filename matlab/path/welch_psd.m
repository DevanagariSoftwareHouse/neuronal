function [frequency, power] = welch_psd(signal, srate, window_seconds, overlap_fraction)
%WELCH_PSD One-sided Welch power spectral density (power units^2/Hz).
% Welch (1967); Bruns (2004). Input: finite real vector, sampling rate Hz.
% Uses one segment window at a time; choose short input blocks for large LFP.
%
%   SIGNATURE DESCRIPTION
%     signal — sampled signal; units and sample axis are given in the notes above.
%     srate — sampling rate in Hz.
%     window_seconds — window duration in seconds.
%     overlap_fraction — the overlap fraction value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     frequency — frequency axis in Hz.
%     power — power spectral density in signal-units squared per Hz.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [frequency, power] = welch_psd(signal, srate, window_seconds, overlap_fraction);
%
if nargin<3 || isempty(window_seconds), window_seconds=4; end
if nargin<4 || isempty(overlap_fraction), overlap_fraction=0.5; end
validateattributes(signal,{'numeric'},{'real','vector','nonempty','finite'});
validateattributes(srate,{'numeric'},{'scalar','finite','positive'});
assert(overlap_fraction>=0 && overlap_fraction<1,'Invalid overlap fraction');
signal=double(signal(:));
n=round(window_seconds*srate);
assert(n>=8 && numel(signal)>=n,'Signal is shorter than Welch window');
window=hann(n,'periodic');
noverlap=floor(n*overlap_fraction);
[power,frequency]=pwelch(signal,window,noverlap,max(256,2^nextpow2(n)),srate);
end

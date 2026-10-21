function [frequency, power] = welch_psd(signal, srate, window_seconds, overlap_fraction)
%WELCH_PSD One-sided Welch power spectral density (power units^2/Hz).
% Welch (1967); Bruns (2004). Input: finite real vector, sampling rate Hz.
% Uses one segment window at a time; choose short input blocks for large LFP.
%
%   SYNTAX
%     [frequency, power] = welch_psd(signal, srate, window_seconds, overlap_fraction)
%
%   INPUTS
%     signal: Nonempty finite real vector, at least one window long.
%     srate: Finite positive sampling rate in Hz.
%     window_seconds: Window duration in seconds, rounded to samples; default 4, >=8 samples.
%     overlap_fraction: Fraction in [0,1); default 0.5; overlap samples rounded down.
%
%   OUTPUTS
%     frequency: Column frequency axis in Hz.
%     power: Matching one-sided PSD in signal-units squared/Hz.
%
%   Requires Signal Processing Toolbox (hann, pwelch).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     [f, p] = welch_psd(x,fs,2,0.5);
%     plot(f,p); xlabel('Frequency (Hz)'); ylabel('PSD (signal units squared/Hz)');
%     % A peak should appear near the simulated 8-Hz component.
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

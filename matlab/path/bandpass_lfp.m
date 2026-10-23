function filtered = bandpass_lfp(signal, srate, band_hz, order)
%BANDPASS_LFP Zero-phase Butterworth filter for a finite LFP vector.
% Filtering is not artifact removal; filtfilt introduces edge transients.
%
%   SYNTAX
%     filtered = bandpass_lfp(signal, srate, band_hz, order)
%
%   INPUTS
%     signal: Finite real vector with more than max(30,6*order) samples.
%     srate: Positive sampling rate in Hz.
%     band_hz: [low high] Hz, strictly inside (0,srate/2).
%     order: Positive integer Butterworth prototype order; default 4.
%
%   OUTPUTS
%     filtered: Double vector with the same orientation and units as signal.
%
%   Requires Signal Processing Toolbox (butter, zp2sos, filtfilt).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     y = bandpass_lfp(x,fs,[4 12],4);
%     % Inspect/discard edge transients before downstream phase analysis.
%
if nargin<4 || isempty(order), order=4; end
validateattributes(signal,{'numeric'},{'real','vector','finite'});
validateattributes(srate,{'numeric'},{'scalar','positive','finite'});
assert(numel(band_hz)==2 && 0<band_hz(1) && ...
    band_hz(1)<band_hz(2) && band_hz(2)<srate/2, ...
    'Band must lie strictly inside (0, Nyquist)');
validateattributes(order,{'numeric'},{'scalar','integer','positive'});
was_row=isrow(signal);
x=double(signal(:));
assert(numel(x)>max(30,6*order),'Input is too short for zero-phase filtering');
[z,p,k]=butter(order,band_hz/(srate/2),'bandpass');
[sos,g]=zp2sos(z,p,k);
filtered=filtfilt(sos,g,x);
if was_row, filtered=filtered.'; end
end

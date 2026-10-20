function [psi,frequency,coherency] = phase_slope_index(a,b,srate,band_hz,window_seconds)
%PHASE_SLOPE_INDEX Frequency-neighbor coherency phase-slope statistic.
% Nolte et al. (2008). Unnormalized draft; no jackknife z-score/sign inference.
%
%   SIGNATURE DESCRIPTION
%     a — the a value; expected shape, units, and constraints are stated in the notes above.
%     b — the b value; expected shape, units, and constraints are stated in the notes above.
%     srate — sampling rate in Hz.
%     band_hz — two-element frequency band in Hz.
%     window_seconds — window duration in seconds.
%   RETURNS
%     psi — the returned value; see the summary above for meaning and units.
%     frequency — frequency axis in Hz.
%     coherency — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [psi, frequency, coherency] = phase_slope_index(a, b, srate, band_hz, window_seconds);
%
if nargin<5 || isempty(window_seconds), window_seconds=4; end
x=double(a(:)); y=double(b(:));
assert(numel(x)==numel(y) && all(isfinite(x)) && all(isfinite(y)));
n=round(window_seconds*srate);
assert(n>=8 && numel(x)>=2*n,'At least two windows are required');
w=hann(n,'periodic'); overlap=floor(n/2); nfft=max(256,2^nextpow2(n));
[cxy,frequency]=cpsd(x,y,w,overlap,nfft,srate);
[pxx,~]=pwelch(x,w,overlap,nfft,srate);
[pyy,~]=pwelch(y,w,overlap,nfft,srate);
coherency=cxy./sqrt(max(pxx.*pyy,realmin));
selected=find(frequency>=band_hz(1)&frequency<=band_hz(2));
assert(numel(selected)>=3 && all(diff(selected)==1),'Band needs >=3 adjacent bins');
psi=imag(sum(conj(coherency(selected(1:end-1))).*coherency(selected(2:end))));
end

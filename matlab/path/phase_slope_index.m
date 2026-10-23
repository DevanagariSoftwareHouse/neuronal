function [psi,frequency,coherency] = phase_slope_index(a,b,srate,band_hz,window_seconds)
%PHASE_SLOPE_INDEX Frequency-neighbor coherency phase-slope statistic.
% Nolte et al. (2008). Unnormalized draft; no jackknife z-score/sign inference.
%
%   SYNTAX
%     [psi,frequency,coherency] = phase_slope_index(a,b,srate,band_hz,window_seconds)
%
%   INPUTS
%     a: Finite real signal vector.
%     b: Matching synchronous finite real signal vector.
%     srate: Positive sampling rate in Hz.
%     band_hz: Inclusive [low high] Hz containing >=3 adjacent spectral bins.
%     window_seconds: Welch window duration; default 4; >=8 samples/window and >=2 windows of
%       data.
%
%   OUTPUTS
%     psi: Scalar unnormalized imaginary neighbor-coherency product sum within band.
%     frequency: Full spectral frequency column in Hz.
%     coherency: Matching complex normalized cross-spectrum.
%
%   Requires Signal Processing Toolbox (hann, cpsd, pwelch).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     y = circshift(x,3)+0.2*randn(size(x));
%     [psi, f, c] = phase_slope_index(x,y,fs,[4 12],2);
%     % This example does not establish a calibrated direction/sign inference.
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

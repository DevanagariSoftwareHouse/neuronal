function [frequency, coherence] = coherence_spectrum(a,b,srate,window_seconds)
%COHERENCE_SPECTRUM Welch magnitude-squared coherence, 0..1.
% Bastos & Schoffelen (2016): coherence is not directed connectivity.
%
%   SYNTAX
%     [frequency, coherence] = coherence_spectrum(a,b,srate,window_seconds)
%
%   INPUTS
%     a: Finite signal vector.
%     b: Matching finite signal vector sampled synchronously.
%     srate: Positive sampling rate in Hz.
%     window_seconds: Window length in seconds; default 4; at least 8 samples per window and
%       two windows of data.
%
%   OUTPUTS
%     frequency: Column frequency axis in Hz.
%     coherence: Matching magnitude-squared coherence in [0,1].
%
%   Requires Signal Processing Toolbox (hann, mscohere).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     y = x + randn(size(x));
%     [f, c] = coherence_spectrum(x,y,fs,2);
%     % Shared components can produce coherence without direct coupling.
%
if nargin<4 || isempty(window_seconds), window_seconds=4; end
x=double(a(:)); y=double(b(:));
assert(numel(x)==numel(y) && all(isfinite(x)) && all(isfinite(y)), ...
    'Signals must match and be finite');
n=round(window_seconds*srate);
assert(n>=8 && numel(x)>=2*n,'Need at least two windows');
w=hann(n,'periodic'); noverlap=floor(n/2);
[coherence,frequency]=mscohere(x,y,w,noverlap,max(256,2^nextpow2(n)),srate);
end

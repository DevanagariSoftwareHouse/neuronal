function [frequency,fractal_power,oscillatory_power,total_power] = irasa_decomposition(signal,srate,window_seconds,resampling_factors)
%IRASA_DECOMPOSITION Exploratory irregular-resampling autospectral analysis.
% Wen & Liu (2016). Median geometric mean estimates fractal spectrum.
% This simplified whole-record implementation omits edge/bias diagnostics.
%
%   SYNTAX
%     [frequency,fractal_power,oscillatory_power,total_power] = irasa_decomposition(signal,srate,window_seconds,resampling_factors)
%
%   INPUTS
%     signal: Finite real vector, longer than two windows and sufficiently long after
%       reciprocal resampling.
%     srate: Positive sampling rate in Hz.
%     window_seconds: Welch window length in seconds; default 4; >=16 samples.
%     resampling_factors: Factors strictly between 1 and 2; default 1.1:0.1:1.9.
%
%   OUTPUTS
%     frequency: Column frequency axis in Hz.
%     fractal_power: Median resampled geometric-mean PSD.
%     oscillatory_power: max(0,total_power-fractal_power), same PSD units.
%     total_power: Original Welch PSD in signal-units squared/Hz.
%
%   Requires Signal Processing Toolbox (hann, pwelch, resample).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     [f, fractal, oscillatory, total] = irasa_decomposition(x,fs,2,1.1:0.2:1.9);
%     % The residual is clipped at zero; inspect the total and fractal spectra.
%
if nargin<3 || isempty(window_seconds), window_seconds=4; end
if nargin<4 || isempty(resampling_factors), resampling_factors=1.1:.1:1.9; end
x=double(signal(:));
assert(all(isfinite(x)) && srate>0 && numel(x)>2*round(window_seconds*srate));
n=round(window_seconds*srate); assert(n>=16);
window=hann(n,'periodic'); nfft=max(256,2^nextpow2(n));
[total_power,frequency]=pwelch(x,window,floor(n/2),nfft,srate);
spectra=zeros(numel(frequency),numel(resampling_factors));
for k=1:numel(resampling_factors)
    h=resampling_factors(k);
    assert(h>1 && h<2,'IRASA factors should be between 1 and 2');
    [p,q]=rat(h,1e-6);
    stretched=resample(x,p,q); compressed=resample(x,q,p);
    assert(numel(stretched)>=n && numel(compressed)>=n, ...
        'Signal too short for a reciprocal resampling factor');
    up=pwelch(stretched,window,floor(n/2),nfft,srate);
    down=pwelch(compressed,window,floor(n/2),nfft,srate);
    spectra(:,k)=sqrt(max(0,up).*max(0,down));
end
fractal_power=median(spectra,2);
oscillatory_power=max(0,total_power-fractal_power);
end

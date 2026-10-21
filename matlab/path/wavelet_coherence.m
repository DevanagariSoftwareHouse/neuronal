function [coherence,frequency,time] = wavelet_coherence(a,b,srate,frequencies,cycles,smoothing_seconds)
%WAVELET_COHERENCE Exploratory time-smoothed Morlet coherence.
% No cross-scale smoothing; exclude edge samples before inference.
%
%   SYNTAX
%     [coherence,frequency,time] = wavelet_coherence(a,b,srate,frequencies,cycles,smoothing_seconds)
%
%   INPUTS
%     a: Finite real signal vector.
%     b: Matching synchronous finite real signal vector.
%     srate: Positive sampling rate in Hz.
%     frequencies: Frequency vector strictly inside (0,srate/2).
%     cycles: Morlet width in cycles >=3; default 6.
%     smoothing_seconds: Positive smoothing duration; default 0.5; input longer than
%       max(3,round(smoothing_seconds*srate)); samples*frequencies <=5e6.
%
%   OUTPUTS
%     coherence: Frequencies-by-samples magnitude-squared coherence with wavelet edges marked
%       NaN.
%     frequency: Column of requested frequencies in Hz.
%     time: Samples-by-1 time vector in seconds, starting at zero.
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     y = x+randn(size(x));
%     [c, f, time] = wavelet_coherence(x,y,fs,4:2:30,6,0.5);
%     % NaN edge regions must be excluded from summaries.
%
if nargin<5 || isempty(cycles), cycles=6; end
if nargin<6 || isempty(smoothing_seconds), smoothing_seconds=.5; end
x=double(a(:)); y=double(b(:)); frequency=double(frequencies(:));
assert(numel(x)==numel(y) && all(isfinite(x)) && all(isfinite(y)));
assert(srate>0 && all(frequency>0 & frequency<srate/2));
n=numel(x); width=max(3,round(smoothing_seconds*srate));
assert(n>width && n*numel(frequency)<=5e6);
time=(0:n-1)'/srate;
coherence=nan(numel(frequency),n);
for k=1:numel(frequency)
    wx=morlet_wavelet(x,srate,frequency(k),cycles);
    wy=morlet_wavelet(y,srate,frequency(k),cycles);
    cross=movmean(wx.*conj(wy),width);
    px=movmean(abs(wx).^2,width);
    py=movmean(abs(wy).^2,width);
    value=abs(cross).^2./max(px.*py,realmin);
    coherence(k,:)=min(1,real(value))';
    edge=min(ceil(n/2),ceil(3.5*cycles*srate/(2*pi*frequency(k))));
    coherence(k,1:edge)=NaN;
    coherence(k,n-edge+1:n)=NaN;
end
end

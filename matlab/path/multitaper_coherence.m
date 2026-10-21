function [frequency,coherence] = multitaper_coherence(a,b,srate,segment_seconds,time_bandwidth,tapers)
%MULTITAPER_COHERENCE Magnitude-squared coherency from averaged DPSS spectra.
% Related to Chronux/Pesaran et al. (2018); no jackknife or trial statistics.
%
%   SYNTAX
%     [frequency,coherence] = multitaper_coherence(a,b,srate,segment_seconds,time_bandwidth,tapers)
%
%   INPUTS
%     a: Finite real signal vector.
%     b: Matching synchronous finite real signal vector.
%     srate: Positive sampling rate in Hz.
%     segment_seconds: Segment duration; default 4; >=16 samples per segment and >=2 segments
%       of data.
%     time_bandwidth: DPSS time-bandwidth product >1; default 3.
%     tapers: Integer count >=1 and <2*time_bandwidth; default floor(2*time_bandwidth-1).
%
%   OUTPUTS
%     frequency: Column frequency axis in Hz.
%     coherence: Matching magnitude-squared coherence in [0,1].
%
%   Requires Signal Processing Toolbox (dpss).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     y = x+randn(size(x));
%     [f, c] = multitaper_coherence(x,y,fs,2,3,5);
%     % Segments overlap by approximately 50 percent.
%
if nargin<4 || isempty(segment_seconds), segment_seconds=4; end
if nargin<5 || isempty(time_bandwidth), time_bandwidth=3; end
if nargin<6 || isempty(tapers), tapers=floor(2*time_bandwidth-1); end
x=double(a(:)); y=double(b(:)); n=numel(x);
assert(numel(y)==n && all(isfinite(x)) && all(isfinite(y)));
assert(srate>0 && time_bandwidth>1 && tapers>=1 && ...
    tapers<2*time_bandwidth);
width=round(segment_seconds*srate);
assert(width>=16 && n>=2*width,'At least two data segments needed');
step=width-floor(width/2); starts=1:step:n-width+1;
w=dpss(width,time_bandwidth,tapers);
nfft=2^nextpow2(width);
nf=floor(nfft/2)+1;
px=zeros(nf,1); py=px; pxy=complex(px);
for start=starts
    i=start:start+width-1;
    xx=bsxfun(@times,x(i)-mean(x(i)),w);
    yy=bsxfun(@times,y(i)-mean(y(i)),w);
    X=fft(xx,nfft,1); Y=fft(yy,nfft,1);
    X=X(1:nf,:); Y=Y(1:nf,:);
    px=px+sum(abs(X).^2,2);
    py=py+sum(abs(Y).^2,2);
    pxy=pxy+sum(X.*conj(Y),2);
end
coherence=abs(pxy).^2./max(px.*py,realmin);
coherence=min(1,max(0,real(coherence)));
frequency=(0:nf-1)'*srate/nfft;
end

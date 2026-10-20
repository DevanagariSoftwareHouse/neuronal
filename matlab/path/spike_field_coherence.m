function [frequency,coherence] = spike_field_coherence(lfp,spike_times,srate,window_seconds)
%SPIKE_FIELD_COHERENCE Magnitude-squared coherence of binned spikes and LFP.
% Field-potential coding analysis; NOT pairwise phase consistency.
% spike_times in seconds, same zero time origin as LFP.
%
%   SYNTAX
%     [frequency,coherence] = spike_field_coherence(lfp,spike_times,srate,window_seconds)
%
%   INPUTS
%     lfp: Finite real LFP vector.
%     spike_times: Finite timestamps in [0,numel(lfp)/srate), in seconds.
%     srate: Positive sampling rate in Hz shared by the LFP and spike bins.
%     window_seconds: Window duration in seconds; default 4; >=16 samples/window and >=2
%       windows of data.
%
%   OUTPUTS
%     frequency: Column frequency axis in Hz.
%     coherence: Matching magnitude-squared coherence between LFP and binned counts.
%
%   Requires Signal Processing Toolbox (hann, mscohere).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     spikes = (0.1:0.125:9.8)';
%     [f, c] = spike_field_coherence(x,spikes,fs,2);
%     % Spikes are counted in sample bins, preserving multiple events per bin.
%
if nargin<4 || isempty(window_seconds), window_seconds=4; end
x=double(lfp(:)); t=double(spike_times(:)); n=numel(x);
assert(all(isfinite(x)) && all(isfinite(t)) && srate>0);
assert(all(t>=0) && all(t<n/srate),'Event outside recording');
segment=round(window_seconds*srate);
assert(segment>=16 && n>=2*segment,'Require at least two segments');
sample=floor(t*srate)+1;
counts=accumarray(sample,1,[n 1]);
w=hann(segment,'periodic');
[coherence,frequency]=mscohere(counts,x,w,floor(segment/2), ...
    2^nextpow2(segment),srate);
end

function [average,lags_s,used] = spike_triggered_average(signal,spike_times,srate,pre_s,post_s)
%SPIKE_TRIGGERED_AVERAGE Average LFP samples relative to point-process events.
% Excludes spikes with incomplete windows; not corrected for shared trial drive.
%
%   SYNTAX
%     [average,lags_s,used] = spike_triggered_average(signal,spike_times,srate,pre_s,post_s)
%
%   INPUTS
%     signal: Finite sampled vector.
%     spike_times: Finite event timestamps in seconds, first sample at zero.
%     srate: Positive sampling rate in Hz.
%     pre_s: Nonnegative duration before each event in seconds.
%     post_s: Nonnegative duration after each event in seconds.
%
%   OUTPUTS
%     average: Column mean over complete event windows; all NaN if none retained.
%     lags_s: Column relative time axis in seconds, both rounded endpoints included.
%     used: Scalar number of complete windows averaged.
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     [average, lags_s, used] = spike_triggered_average(x,[1 2 3],fs,0.1,0.2);
%     % Event centers use round(time*fs)+1, and incomplete windows are skipped.
%
x=double(signal(:)); t=double(spike_times(:));
assert(all(isfinite(x)) && all(isfinite(t)) && srate>0 && pre_s>=0 && post_s>=0);
before=round(pre_s*srate); after=round(post_s*srate);
lags=(-before:after)'; lags_s=lags/srate;
sum_window=zeros(numel(lags),1); used=0;
indices=round(t*srate)+1;
for k=1:numel(indices)
    idx=indices(k)+lags;
    if idx(1)<1 || idx(end)>numel(x), continue; end
    sum_window=sum_window+x(idx);
    used=used+1;
end
average=nan(numel(lags),1);
if used>0, average=sum_window/used; end
end

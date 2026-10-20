function [average,lags_s,used] = spike_triggered_average(signal,spike_times,srate,pre_s,post_s)
%SPIKE_TRIGGERED_AVERAGE Average LFP samples relative to point-process events.
% Excludes spikes with incomplete windows; not corrected for shared trial drive.
%
%   SIGNATURE DESCRIPTION
%     signal — sampled signal; units and sample axis are given in the notes above.
%     spike_times — spike/event timestamps in seconds.
%     srate — sampling rate in Hz.
%     pre_s — the pre s value; expected shape, units, and constraints are stated in the notes above.
%     post_s — the post s value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     average — the returned value; see the summary above for meaning and units.
%     lags_s — the returned value; see the summary above for meaning and units.
%     used — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [average, lags_s, used] = spike_triggered_average(signal, spike_times, srate, pre_s, post_s);
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

function [average,lags_s,used] = event_triggered_average(signal,event_times,srate,pre_s,post_s)
%EVENT_TRIGGERED_AVERAGE Average a sampled signal around point-process events.
% [AVERAGE, LAGS_S, USED] = EVENT_TRIGGERED_AVERAGE(SIGNAL, EVENTS, FS, PRE, POST)
% With spike times as EVENTS and LFP as SIGNAL this is the spike-triggered
% average; stimulus, phase or ripple timestamps work identically.
% SIGNAL is one finite vector sampled from time zero; EVENTS in seconds.
% Lag zero is the NEAREST sample round(EVENT*FS)+1; lags span
% round(-PRE*FS):round(POST*FS), both endpoints included.
% Events with incomplete windows are excluded; USED counts the rest.
% AVERAGE is NaN when no event has a full window.
% Not corrected for shared trial drive or common stimulus locking.
% Equivalent to the mean over EVENT_ALIGNED_SEGMENTS(..., 'Anchor',
% 'nearest', 'Boundary', 'drop').
% See also event_aligned_segments, peri_event_histogram.
x=double(signal(:)); t=double(event_times(:));
assert(all(isfinite(x)) && all(isfinite(t)) && srate>0 && pre_s>=0 && post_s>=0);
[segments,lags_s]=event_aligned_segments(x,t,srate,[-pre_s post_s],1, ...
    'Anchor','nearest','Boundary','drop');
lags_s=lags_s(:);
used=size(segments,1);
average=nan(numel(lags_s),1);
if used>0, average=mean(segments,1).'; end
end

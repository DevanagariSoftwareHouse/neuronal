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
% Accumulates one window at a time with O(number of lags) working memory.
% See also event_aligned_segments, peri_event_histogram.
validateattributes(signal, {'numeric'}, {'vector','real','finite','nonempty'});
assert(isempty(event_times) || isvector(event_times), 'Expected event timestamps as a vector.');
validateattributes(event_times, {'numeric'}, {'real','finite'});
validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(pre_s, {'numeric'}, {'scalar','real','finite','nonnegative'});
validateattributes(post_s, {'numeric'}, {'scalar','real','finite','nonnegative'});
x = double(signal(:));
t = double(event_times(:));
offsets = (-round(pre_s*srate):round(post_s*srate))';
lags_s = offsets/double(srate);
accumulator = zeros(numel(offsets),1);
used = 0;
% Accumulate one window at a time: no dense events-by-lags allocation.
for k = 1:numel(t)
    center = round(t(k)*double(srate)) + 1;
    indices = center + offsets;
    if indices(1) < 1 || indices(end) > numel(x), continue; end
    accumulator = accumulator + x(indices);
    used = used + 1;
end
average = nan(numel(offsets),1);
if used > 0, average = accumulator/used; end
end

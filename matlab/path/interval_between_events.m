function nodes = interval_between_events(N, fs, events_s)
%INTERVAL_BETWEEN_EVENTS Generate gaps between consecutive ordered events.
% nodes = interval_between_events(N, fs, events_s)
% Input times must be nondecreasing; tied events produce empty intervals
% that are omitted. source_index is the index of the left input event.
% Example: w = interval_between_events(1000,500,[.1 .3 .3 .8]);

validateattributes(events_s, {'numeric'}, {'2d','real','finite'});
assert(isvector(events_s) || isempty(events_s), 'interval:Shape', 'Expected a vector.');
e = double(events_s(:));
assert(all(diff(e)>=0), 'interval:Order', 'Events must be nondecreasing.');
nodes = interval_from_bounds(N,fs,[e(1:end-1),e(2:end)]);
end

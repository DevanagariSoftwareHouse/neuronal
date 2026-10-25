function nodes = interval_between_events(N, fs, events_s, k)
%INTERVAL_BETWEEN_EVENTS Generate gaps between consecutive ordered events.
% count = interval_between_events(N, fs, events_s)
% node = interval_between_events(N, fs, events_s, k)
% nodes = interval_between_events(N, fs, events_s, 'all')
% Input times must be nondecreasing; tied events produce empty intervals
% that are omitted. source_index is the index of the left input event.
% Example: w = interval_between_events(1000,500,[.1 .3 .3 .8], 'all');
% Omit final k (or pass []) to return the scalar number of intervals.
% Pass a positive integer k to retrieve one record; pass 'all' for all records.
% Count/index queries still scan the input data or regenerate seeded draws.

if nargin < 4, k = []; end
validateattributes(events_s, {'numeric'}, {'2d','real','finite'});
assert(isvector(events_s) || isempty(events_s), 'interval:Shape', 'Expected a vector.');
e = double(events_s(:));
assert(all(diff(e)>=0), 'interval:Order', 'Events must be nondecreasing.');
nodes = interval_from_bounds(N,fs,[e(1:end-1),e(2:end)], 'all');
nodes = interval_select(nodes,k);
end

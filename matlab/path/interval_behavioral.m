function nodes = interval_behavioral(N, fs, starts_s, stops_s, k)
%INTERVAL_BEHAVIORAL Generate intervals from paired behavioral or trial boundaries.
% count = interval_behavioral(N, fs, starts_s, stops_s)
% node = interval_behavioral(N, fs, starts_s, stops_s, k)
% nodes = interval_behavioral(N, fs, starts_s, stops_s, 'all')
% Preserves row order and overlap; clips to session. source_index maps to
% the original trial, even when outside or zero-duration trials are dropped.
% Example: w = interval_behavioral(1000,500,[0 .8],[.5 1.5], 'all');
% Omit final k (or pass []) to return the scalar number of intervals.
% Pass a positive integer k to retrieve one record; pass 'all' for all records.
% Count/index queries still scan the input data or regenerate seeded draws.

if nargin < 5, k = []; end
validateattributes(starts_s, {'numeric'}, {'2d','real','finite'});
assert(isvector(starts_s) || isempty(starts_s), 'interval:Shape', 'Expected a vector.');
validateattributes(stops_s, {'numeric'}, {'2d','real','finite','numel',numel(starts_s)});
assert(isvector(stops_s) || isempty(stops_s), 'interval:Shape', 'Expected a vector.');
nodes = interval_from_bounds(N,fs,[double(starts_s(:)),double(stops_s(:))], 'all');
nodes = interval_select(nodes,k);
end

function nodes = interval_from_bounds(N, fs, bounds, k)
%INTERVAL_FROM_BOUNDS Convert K-by-2 time bounds in seconds to sampled interval records.
% count = interval_from_bounds(N, fs, bounds)
% node = interval_from_bounds(N, fs, bounds, k)
% nodes = interval_from_bounds(N, fs, bounds, 'all')
% Clips each [t0,t1) to [0,N/fs); drops empty intersections. Input rows
% are never sorted or merged. source_index preserves the input row number.
% Clock: t=(sample-1)/fs. first:last are inclusive, and can be empty for
% a positive-duration sub-sample interval. Near-integer sample coordinates
% are snapped within 8 ULP to stabilize arithmetic at grid boundaries.
% Common fields: t0, t1, duration_s, first, last, n_samples, window,
% n_windows, source_index. Empty output is a typed 0-by-1 struct array.
% Example: w = interval_from_bounds(1000,500,[-1 .5; .25 1], 'all');
% Omit final k (or pass []) to return the scalar number of intervals.
% Pass a positive integer k to retrieve one record; pass 'all' for all records.
% Count/index queries still scan the input data or regenerate seeded draws.

if nargin < 4, k = []; end
T = interval_session(N,fs);
validateattributes(bounds, {'numeric'}, {'2d','real','finite','ncols',2});
bounds = double(bounds);
assert(all(bounds(:,2) >= bounds(:,1)), 'interval:Bounds', 'End precedes start.');
left = max(0,bounds(:,1));
right = min(T,bounds(:,2));
source = find(right > left);
template = struct('t0',0,'t1',0,'duration_s',0,'first',0,'last',0, ...
    'n_samples',0,'window',0,'n_windows',numel(source),'source_index',0);
nodes = repmat(template,numel(source),1);
for j = 1:numel(source)
    i = source(j);
    q = [left(i),right(i)]*double(fs);
    nearest = round(q);
    snap = abs(q-nearest) <= 8*eps(max(1,abs(q)));
    q(snap) = nearest(snap);
    first = min(double(N)+1,max(1,ceil(q(1))+1));
    last = min(double(N),max(0,ceil(q(2))));
    nodes(j) = struct('t0',left(i),'t1',right(i), ...
        'duration_s',right(i)-left(i),'first',first,'last',last, ...
        'n_samples',max(0,last-first+1),'window',j, ...
        'n_windows',numel(source),'source_index',i);
end
nodes = interval_select(nodes,k);
end

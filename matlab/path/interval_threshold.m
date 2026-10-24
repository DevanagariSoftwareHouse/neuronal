function nodes = interval_threshold(N, fs, x, threshold, min_duration_s, k)
%INTERVAL_THRESHOLD Generate contiguous runs strictly above a scalar threshold.
% count = interval_threshold(N, fs, x, threshold, min_duration_s)
% node = interval_threshold(N, fs, x, threshold, min_duration_s, k)
% nodes = interval_threshold(N, fs, x, threshold, min_duration_s, 'all')
% x has N samples; NaNs break runs, infinities are rejected. Each selected
% sample occupies [(i-1)/fs,i/fs). Duration filtering occurs after runs
% are found; no gap filling or smoothing. Default min_duration_s=0.
% Example: w = interval_threshold(5,10,[0 2 3 NaN 4],1,0, 'all');
% Omit final k (or pass []) to return the scalar number of intervals.
% Pass a positive integer k to retrieve one record; pass 'all' for all records.
% Count/index queries still scan the input data or regenerate seeded draws.

if nargin < 6, k = []; end
if nargin < 5, min_duration_s = 0; end
interval_session(N,fs);
validateattributes(x, {'numeric'}, {'vector','real','numel',double(N)});
assert(~any(isinf(x(:))), 'interval:Data', 'Infinite samples are unsupported.');
validateattributes(threshold, {'numeric'}, {'scalar','real','finite'});
validateattributes(min_duration_s, {'numeric'}, {'scalar','real','finite','nonnegative'});
mask = double(x(:))>double(threshold);
d = diff([false;mask;false]);
a = find(d==1); b = find(d==-1);
keep = (b-a)/double(fs) >= double(min_duration_s);
nodes = interval_from_bounds(N,fs,[(a(keep)-1)/double(fs),(b(keep)-1)/double(fs)], 'all');
nodes = interval_select(nodes,k);
end

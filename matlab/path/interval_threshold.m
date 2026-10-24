function nodes = interval_threshold(N, fs, x, threshold, min_duration_s)
%INTERVAL_THRESHOLD Generate contiguous runs strictly above a scalar threshold.
% nodes = interval_threshold(N, fs, x, threshold, min_duration_s)
% x has N samples; NaNs break runs, infinities are rejected. Each selected
% sample occupies [(i-1)/fs,i/fs). Duration filtering occurs after runs
% are found; no gap filling or smoothing. Default min_duration_s=0.
% Example: w = interval_threshold(5,10,[0 2 3 NaN 4],1,0);

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
nodes = interval_from_bounds(N,fs,[(a(keep)-1)/double(fs),(b(keep)-1)/double(fs)]);
end

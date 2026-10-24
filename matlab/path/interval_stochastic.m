function nodes = interval_stochastic(N, fs, n_windows, width_range_s, seed, k)
%INTERVAL_STOCHASTIC Draw complete random windows with reproducible local RNG state.
% count = interval_stochastic(N, fs, n_windows, width_range_s, seed)
% node = interval_stochastic(N, fs, n_windows, width_range_s, seed, k)
% nodes = interval_stochastic(N, fs, n_windows, [min_s max_s], seed, 'all')
% Width is uniform over the range; onset conditional on width is uniform
% over [0,T-width]. Equal limits give fixed width. Windows are independent
% draws, may overlap, and remain in draw order. Global RNG is restored.
% This generates random windows, NOT a stationary-bootstrap resample.
% Example: w = interval_stochastic(1000,500,10,[.1 .3],42, 'all');
% Omit final k (or pass []) to return the scalar number of intervals.
% Pass a positive integer k to retrieve one record; pass 'all' for all records.
% Count/index queries still scan the input data or regenerate seeded draws.

if nargin < 6, k = []; end
T = interval_session(N,fs);
validateattributes(n_windows, {'numeric'}, {'scalar','real','finite','integer','nonnegative'});
validateattributes(width_range_s, {'numeric'}, {'vector','numel',2,'real','finite','positive','<=',T});
assert(width_range_s(2)>=width_range_s(1), 'interval:Bounds', 'Width range must be ordered.');
validateattributes(seed, {'numeric'}, {'scalar','real','finite','integer','>=',0,'<=',2^32-1});
old = rng; restore = onCleanup(@() rng(old)); %#ok<NASGU>
rng(double(seed),'twister');
r = double(width_range_s);
w = r(1)+(r(2)-r(1))*rand(double(n_windows),1);
a = (T-w).*rand(double(n_windows),1);
nodes = interval_from_bounds(N,fs,[a,a+w], 'all');
nodes = interval_select(nodes,k);
end

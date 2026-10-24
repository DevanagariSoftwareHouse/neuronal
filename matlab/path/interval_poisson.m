function nodes = interval_poisson(N, fs, rate_hz, seed, k)
%INTERVAL_POISSON Generate exponential renewal intervals for a homogeneous Poisson model.
% count = interval_poisson(N, fs, rate_hz, seed)
% node = interval_poisson(N, fs, rate_hz, seed, k)
% nodes = interval_poisson(N, fs, rate_hz, seed, 'all')
% Starts at time zero, draws iid exponential waits, and retains the final
% right-censored interval at T. Global RNG is restored after generation.
% No Statistics Toolbox. O(number of events) output and expected work.
% Example: w = interval_poisson(1000,500,5,42, 'all');
% Omit final k (or pass []) to return the scalar number of intervals.
% Pass a positive integer k to retrieve one record; pass 'all' for all records.
% Count/index queries still scan the input data or regenerate seeded draws.

if nargin < 5, k = []; end
T = interval_session(N,fs);
validateattributes(rate_hz, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(seed, {'numeric'}, {'scalar','real','finite','integer','>=',0,'<=',2^32-1});
old = rng; restore = onCleanup(@() rng(old)); %#ok<NASGU>
rng(double(seed),'twister');
a = 0; bounds = zeros(0,2);
while a < T
    wait = -log(max(realmin,rand))/double(rate_hz);
    b = min(T,a+wait);
    assert(b > a, 'interval:Resolution', 'Waiting time is below time precision.');
    bounds(end+1,:) = [a,b]; %#ok<AGROW>
    a = b;
end
nodes = interval_from_bounds(N,fs,bounds, 'all');
nodes = interval_select(nodes,k);
end

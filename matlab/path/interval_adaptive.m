function nodes = interval_adaptive(N, fs, mass, target, k)
%INTERVAL_ADAPTIVE Partition samples by accumulated nonnegative mass.
% count = interval_adaptive(N, fs, mass, target)
% node = interval_adaptive(N, fs, mass, target, k)
% nodes = interval_adaptive(N, fs, mass, target, 'all')
% mass has N nonnegative finite sample weights (e.g. abs(lfp).^2/fs for
% energy). Close each block after reaching target and retain the tail.
% Overshoot remains in that block; zero-mass data yields the whole session.
% O(N) scan; interval duration adapts to mass, without a stationarity claim.
% Example: w = interval_adaptive(6,10,[0 2 1 0 4 0],3, 'all');
% Omit final k (or pass []) to return the scalar number of intervals.
% Pass a positive integer k to retrieve one record; pass 'all' for all records.
% Count/index queries still scan the input data or regenerate seeded draws.

if nargin < 5, k = []; end
interval_session(N,fs);
validateattributes(mass, {'numeric'}, {'vector','numel',double(N),'real','finite','nonnegative'});
validateattributes(target, {'numeric'}, {'scalar','real','finite','positive'});
bounds = zeros(0,2); start = 1; total = 0;
for i = 1:double(N)
    total = total+double(mass(i));
    if total >= double(target)
        bounds(end+1,:) = [(start-1)/double(fs),i/double(fs)]; %#ok<AGROW>
        start = i+1; total = 0;
    end
end
if start <= double(N)
    bounds(end+1,:) = [(start-1)/double(fs),double(N)/double(fs)];
end
nodes = interval_from_bounds(N,fs,bounds, 'all');
nodes = interval_select(nodes,k);
end

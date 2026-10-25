function node = interval_uniform(N, fs, n_parts, k)
%INTERVAL_UNIFORM Lazily select an equal-duration partition.
% node = interval_uniform(N, fs, n_parts, k)
% Partitions tile the session. Sample counts may differ by one.
% Example: w = interval_uniform(1001,500,3,2);
% Omit final k (or pass []) to return the number of complete/available windows.
% Counting uses O(1) memory and does not build an interval bank.
% Pass 'all' as final k to return a column struct array of every window.
% Bulk output uses O(number of windows) memory; no sample masks are created.

if nargin == 4 && ischar(k) && isequal(k,'all')
    node = interval_collect(@interval_uniform,{N,fs,n_parts});
    return
end
if nargin < 4, k = []; end
T = interval_session(N,fs);
validateattributes(n_parts, {'numeric'}, {'scalar','real','finite','integer','positive','<=',double(N)});
node = interval_sliding(N,fs,T/double(n_parts),T/double(n_parts),k);
if isempty(k), return; end
node.n_windows = double(n_parts);
end

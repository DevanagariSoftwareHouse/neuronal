function node = interval_uniform(N, fs, n_parts, k)
%INTERVAL_UNIFORM Lazily select an equal-duration partition.
% node = interval_uniform(N, fs, n_parts, k)
% Partitions tile the session. Sample counts may differ by one.
% Example: w = interval_uniform(1001,500,3,2);

T = interval_session(N,fs);
validateattributes(n_parts, {'numeric'}, {'scalar','real','finite','integer','positive','<=',double(N)});
node = interval_sliding(N,fs,T/double(n_parts),T/double(n_parts),k);
node.n_windows = double(n_parts);
end

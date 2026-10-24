function nodes = interval_quantile(N, fs, timestamps_s, n_bins)
%INTERVAL_QUANTILE Partition time at empirical timestamp quantiles.
% nodes = interval_quantile(N, fs, timestamps_s, n_bins)
% Sorts timestamps in [0,T), interpolates ranks 1+(n-1)*p, adds 0 and T.
% Duplicate borders are collapsed: ties can reduce the number of bins and
% equal counts are not guaranteed. This partitions TIME, not amplitudes.
% Example: w = interval_quantile(1000,500,[.1 .2 .8 1.5],2);

T = interval_session(N,fs);
validateattributes(timestamps_s, {'numeric'}, {'vector','real','finite','nonempty','>=',0,'<',T});
validateattributes(n_bins, {'numeric'}, {'scalar','real','finite','integer','positive','<=',numel(timestamps_s)});
x = sort(double(timestamps_s(:)));
r = 1+(numel(x)-1)*(1:double(n_bins)-1)/double(n_bins);
lo = floor(r); hi = ceil(r); w = r-lo;
q = (1-w(:)).*x(lo(:))+w(:).*x(hi(:));
edges = unique([0;q(:);T]);
nodes = interval_from_bounds(N,fs,[edges(1:end-1),edges(2:end)]);
end

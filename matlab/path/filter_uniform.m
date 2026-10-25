function node = filter_uniform(fs, count, overlap, k)
%FILTER_UNIFORM Count or retrieve full-width frequency intervals over Nyquist.
% N = filter_uniform(FS, COUNT, OVERLAP)
% NODE = filter_uniform(FS, COUNT, OVERLAP, K); K is 1-based or 'all'.
% Width=FS/(2*COUNT), hop=width*(1-OVERLAP). Only complete intervals
% are returned; a non-divisible hop can leave a final uncovered tail.
% OVERLAP is the shared fraction of neighboring interval widths, in [0,1).
% NODE contains low/high/center/bandwidth in Hz and a response kind.
% Example: n = filter_uniform(500,8,.5); % 15, not 8 expanded bands
%          band = filter_uniform(500,8,.5,n);
if nargin < 4, k = []; end
validateattributes(count,{'numeric'},{'scalar','real','finite','integer','positive','<=',2^30});
node=filter_frequency_node(fs,(fs/2)/count,overlap,k);
end

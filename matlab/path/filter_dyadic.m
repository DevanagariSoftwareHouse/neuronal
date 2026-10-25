function node = filter_dyadic(fs, level, overlap, k)
%FILTER_DYADIC Lazy dyadic frequency bank with interval_* conventions.
% N = filter_dyadic(FS, LEVEL, OVERLAP)
% NODE = filter_dyadic(FS, LEVEL, OVERLAP, K); K is 1-based or 'all'.
% Width=Nyquist/2^LEVEL. This specifies bands, not filter coefficients.
% Example: n = filter_dyadic(500,3,.5); % 15
%          band = filter_dyadic(500,3,.5,2);
if nargin < 4, k = []; end
validateattributes(level,{'numeric'},{'scalar','integer','>=',0,'<=',30});
node = filter_uniform(fs,2^level,overlap,k);
end

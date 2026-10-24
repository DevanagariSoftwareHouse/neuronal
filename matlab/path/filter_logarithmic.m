function node = filter_logarithmic(fs, fmin, bands_per_octave, overlap, k)
%FILTER_LOGARITHMIC Lazy constant-ratio bands between FMIN and Nyquist.
% N = filter_logarithmic(FS,FMIN,BANDS_PER_OCTAVE,OVERLAP)
% NODE = filter_logarithmic(...,K); K is 1-based or 'all'.
% Width and overlap are measured in log2 frequency, not linear Hz.
% DC is excluded; only complete bands are returned (possible upper tail).
% Example: b = filter_logarithmic(500,1,4,.5,'all');
if nargin < 5, k = []; end
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(fmin,{'numeric'},{'scalar','real','finite','positive','<',fs/2});
validateattributes(bands_per_octave,{'numeric'},{'scalar','integer','positive'});
validateattributes(overlap,{'numeric'},{'scalar','real','finite','>=',0,'<',1});
width = 1/bands_per_octave; hop = width*(1-overlap);
q = (log2((fs/2)/fmin)-width)/hop;
n = max(0,floor(q+8*eps(max(1,abs(q))))+1);
assert(isfinite(n) && n <= flintmax,'Too many intervals');
if isempty(k), node = n; return; end
if ischar(k) && strcmp(k,'all')
    assert(n <= 1e6,'Use lazy indexing for large banks');
    node = struct('index',{},'count',{},'fs',{},'low',{},'high',{}, ...
        'center',{},'bandwidth',{},'overlap',{},'kind',{});
    for j = 1:n, node(j,1) = filter_logarithmic(fs,fmin,bands_per_octave,overlap,j); end
    return
end
validateattributes(k,{'numeric'},{'scalar','integer','>=',1,'<=',n});
lo = fmin*2^((k-1)*hop); hi = lo*2^width;
if abs(hi-fs/2) <= 16*eps(fs/2), hi = fs/2; end
kind = 'bandpass'; if hi == fs/2, kind = 'high'; end
node = struct('index',k,'count',n,'fs',fs,'low',lo,'high',hi, ...
    'center',sqrt(lo*hi),'bandwidth',hi-lo,'overlap',overlap,'kind',kind);
end

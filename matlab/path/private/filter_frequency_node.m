function node = filter_frequency_node(fs,width,overlap,k)
% Internal lazy linear frequency geometry.
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(width,{'numeric'},{'scalar','real','finite','positive','<=',fs/2});
validateattributes(overlap,{'numeric'},{'scalar','real','finite','>=',0,'<',1});
hop = width*(1-overlap);
q = (fs/2-width)/hop;
n = floor(q + 8*eps(max(1,q)))+1;
assert(n <= flintmax,'Too many intervals for exact indexing');
if isempty(k), node = n; return; end
if ischar(k) && strcmp(k,'all')
    assert(n <= 1e6,'Bulk output exceeds one million intervals; use lazy indexing');
    node = repmat(filter_frequency_node(fs,width,overlap,1),n,1);
    for j = 2:n, node(j) = filter_frequency_node(fs,width,overlap,j); end
    return
end
validateattributes(k,{'numeric'},{'scalar','real','finite','integer','>=',1,'<=',n});
lo = (k-1)*hop; hi = lo+width;
if abs(hi-fs/2) <= 16*eps(fs/2), hi = fs/2; end
kind = 'bandpass';
if lo == 0, kind = 'low'; end
if hi == fs/2, kind = 'high'; end
if lo == 0 && hi == fs/2, kind = 'identity'; end
node = struct('index',k,'count',n,'fs',fs,'low',lo,'high',hi, ...
    'center',(lo+hi)/2,'bandwidth',hi-lo,'overlap',overlap,'kind',kind);
end

function node = interval_sliding(N, fs, width_s, hop_s, k)
%INTERVAL_SLIDING Lazily generate the Kth complete sliding window.
% node = interval_sliding(N, fs, width_s, hop_s, k)
% Positive width and hop are independent, in seconds; hop may exceed width.
% Only complete windows are counted. O(1) storage and work per call.
% Example: w = interval_sliding(1000,500,.5,.25,3);
% Omit final k (or pass []) to return the number of complete/available windows.
% Counting uses O(1) memory and does not build an interval bank.
% Pass 'all' as final k to return a column struct array of every window.
% Bulk output uses O(number of windows) memory; no sample masks are created.

if nargin == 5 && ischar(k) && isequal(k,'all')
    node = interval_collect(@interval_sliding,{N,fs,width_s,hop_s});
    return
end
T = interval_session(N,fs);
validateattributes(width_s, {'numeric'}, {'scalar','real','finite','positive','<=',T});
validateattributes(hop_s, {'numeric'}, {'scalar','real','finite','positive'});
if nargin < 5, k = []; end
width_s = double(width_s); hop_s = double(hop_s);
r = (T-width_s)/hop_s;
assert(isfinite(r) && r < flintmax, 'interval:Resolution', 'Too many windows.');
n = floor(r+8*eps(max(1,r)))+1;
if isempty(k), node = n; return; end
validateattributes(k, {'numeric'}, {'scalar','real','finite','integer','positive'});
k = double(k);
assert(k <= n, 'interval:Index', 'Window index exceeds complete windows.');
t0 = (k-1)*hop_s;
node = interval_from_bounds(N,fs,[t0,min(T,t0+width_s)], 'all');
assert(~isempty(node), 'interval:Resolution', 'Window is below time precision.');
node.window = k; node.source_index = k; node.n_windows = n;
node.hop_s = hop_s;
node.overlap = max(0,1-hop_s/width_s);
end

function node = interval_madic(N, fs, base, level, overlap, k)
%INTERVAL_MADIC Lazily generate an m-adic interval, optionally overlapping.
% node = interval_madic(N, fs, base, level, overlap, k)
% Width = (N/fs)/base^level; hop = width*(1-overlap). Base >= 2.
% With overlap=0 the levels form a nested tree; with overlap>0 they form
% a multiscale cover, without a unique parent for every window.
% Example: w = interval_madic(3000,500,3,2,.5,4);
% Omit final k (or pass []) to return the number of complete/available windows.
% Counting uses O(1) memory and does not build an interval bank.
% Pass 'all' as final k to return a column struct array of every window.
% Bulk output uses O(number of windows) memory; no sample masks are created.

if nargin == 6 && ischar(k) && isequal(k,'all')
    node = interval_collect(@interval_madic,{N,fs,base,level,overlap});
    return
end
if nargin < 6, k = []; end
T = interval_session(N,fs);
validateattributes(base, {'numeric'}, {'scalar','real','finite','integer','>=',2});
validateattributes(level, {'numeric'}, {'scalar','real','finite','integer','nonnegative'});
validateattributes(overlap, {'numeric'}, {'scalar','real','finite','>=',0,'<',1});
parts = double(base)^double(level);
assert(isfinite(parts) && parts <= double(N), 'interval:Resolution', 'Nominal width must be at least one sample.');
width = T/parts;
node = interval_sliding(N,fs,width,width*(1-double(overlap)),k);
if isempty(k), return; end
node.base = double(base); node.level = double(level); node.overlap = double(overlap);
node.frequency_hz = 1/(2*width);
node.phase_rad = mod(-2*pi*node.frequency_hz*node.t0,2*pi);
node.phase_step_rad = pi*(1-double(overlap));
end

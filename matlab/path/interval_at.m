function node = interval_at(N, fs, level, overlap, k)
%INTERVAL_AT Lazily calculate a multiscale overlapping session interval.
% node = interval_at(N, fs, level, overlap, k)
% Backward-compatible entry point for interval_dyadic. N is sample count,
% fs is Hz, level=0 spans the session, overlap is in [0,1), k is 1-based.
% All original fields are retained. Widths below one sample are rejected.
% Clock: t=(sample-1)/fs; bounds are [t0,t1). first:last selects samples.
% frequency_hz and phase_rad describe an aligned 50%-duty square wave;
% restrict it to [t0,t1) to select only this window. No toolbox required.
% Example:
%   get = @(level,o,k) interval_at(1000,500,level,o,k);
%   w = get(2,.5,3);
%   % segment = signal(w.first:w.last);
% See also interval_madic, interval_sliding, interval_from_bounds.
% Omit final k (or pass []) to return the number of complete/available windows.
% Counting uses O(1) memory and does not build an interval bank.
% Pass 'all' as final k to return a column struct array of every window.
% Bulk output uses O(number of windows) memory; no sample masks are created.
% level and overlap may be vectors; 'all' returns their combined bank.

if nargin == 5 && ischar(k) && isequal(k,'all') && ...
        isscalar(level) && isscalar(overlap)
    node = interval_collect(@interval_at,{N,fs,level,overlap});
    return
end
if nargin < 5, k = []; end
node = interval_dyadic(N,fs,level,overlap,k);
end

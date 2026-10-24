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

node = interval_dyadic(N,fs,level,overlap,k);
end

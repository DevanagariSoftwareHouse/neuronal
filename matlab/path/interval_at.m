function node = interval_at(N, fs, level, overlap, k)
%INTERVAL_AT Lazily calculate a multiscale, overlapping session interval.
% NODE = INTERVAL_AT(N, FS, LEVEL, OVERLAP, K)
% N is the session sample count; FS is the sampling rate in Hz.
% LEVEL=0 spans the whole session; LEVEL=1 uses windows of T/2, etc.
% OVERLAP is a fraction in [0,1), e.g. 0.5 for 50% overlap.
% K is the 1-based index of a complete window at this level/overlap.
% The sampled clock is t=(sample-1)/FS; intervals are [t0,t1).
% NODE.first:NODE.last selects the samples (inclusive MATLAB indices).
% NODE.frequency_hz and NODE.phase_rad describe a 50%-duty square
% wave aligned to this window's onset. A periodic square wave alone
% does NOT select a unique window: restrict it to [t0,t1).
% No full-session mask or Signal Processing Toolbox is required.
%
% Example:
%   get = @(level,o,k) interval_at(1000,500,level,o,k);
%   w = get(2,0.5,3);
%   samples = signal(w.first:w.last);
%   for k = 1:w.n_windows
%       node = get(2,0.5,k);  % no bank stored
%   end
% See also event_aligned_segments, spike_counts_edges.

validateattributes(N, {'numeric'}, {'scalar','real','finite','integer','positive'});
validateattributes(fs, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(level, {'numeric'}, {'scalar','real','finite','integer','nonnegative'});
validateattributes(overlap, {'numeric'}, {'scalar','real','finite','>=',0,'<',1});
validateattributes(k, {'numeric'}, {'scalar','real','finite','integer','positive'});

T = double(N) / double(fs);
duration = T / 2^double(level);
hop = duration * (1-double(overlap));
assert(isfinite(hop) && hop > 0, 'Interval hop must be positive.');
% Strictly complete windows, with a small tolerance for arithmetic noise.
n_windows = floor((T-duration)/hop + 16*eps(max(1,(T-duration)/hop))) + 1;
assert(k <= n_windows, 'Window index exceeds available complete windows.');
t0 = (double(k)-1)*hop;
t1 = t0 + duration;
assert(t1 <= T + 16*eps(max(1,T)), 'Window exceeds session.');
t1 = min(t1,T);
% Convert the half-open temporal range to inclusive sample indices.
first = ceil(t0*fs) + 1;
last = min(ceil(t1*fs),double(N));
assert(first <= last, 'Window contains no samples at this sampling rate.');
frequency_hz = 1/(2*duration);
phase_rad = mod(-2*pi*frequency_hz*t0,2*pi);

node = struct('level',double(level), 'overlap',double(overlap), ...
    'window',double(k), 'n_windows',n_windows, ...
    'frequency_hz',frequency_hz, 'phase_rad',phase_rad, ...
    'phase_step_rad',pi*(1-double(overlap)), ...
    't0',t0, 't1',t1, 'duration_s',duration, 'hop_s',hop, ...
    'first',first, 'last',last, 'n_samples',last-first+1);
end

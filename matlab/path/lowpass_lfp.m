function filtered = lowpass_lfp(signal, srate, cutoff_hz, order)
%LOWPASS_LFP Zero-phase Butterworth lowpass filtering.
%   FILTERED = lowpass_lfp(SIGNAL, SRATE, CUTOFF_HZ, ORDER)
%   SIGNAL is samples-by-channels, or a vector (orientation preserved).
%   ORDER defaults to 4. Requires Signal Processing Toolbox.
%   Do not downsample without an appropriate antialiasing filter.
%
%   Example:
%       fs = 500; t = (0:fs*8-1)' / fs;
%       x = sin(2*pi*8*t) + sin(2*pi*90*t);
%       y = lowpass_lfp(x, fs, 30);
    if nargin < 4 || isempty(order), order = 4; end
    validateattributes(signal, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(cutoff_hz, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(order, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});
    assert(cutoff_hz < srate/2, 'Cutoff must be below Nyquist');
    was_row = isrow(signal);
    if isvector(signal), x = double(signal(:)); else, x = double(signal); end
    assert(size(x, 1) > max(30, 6*order), ...
        'Insufficient samples for zero-phase filtering');
    [z, p, k] = butter(order, cutoff_hz/(srate/2), 'low');
    [sos, g] = zp2sos(z, p, k);
    filtered = filtfilt(sos, g, x);
    if was_row, filtered = filtered.'; end
end

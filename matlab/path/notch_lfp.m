function filtered = notch_lfp(signal, srate, center_hz, bandwidth_hz)
%NOTCH_LFP Zero-phase Butterworth bandstop for line interference.
%   FILTERED = notch_lfp(SIGNAL, SRATE, CENTER_HZ, BANDWIDTH_HZ)
%   Defaults CENTER_HZ = 60 Hz, BANDWIDTH_HZ = 2 Hz.
%   Samples-by-channels; vectors preserve row/column orientation.
%   Requires Signal Processing Toolbox.
%
%   Example:
%       fs = 500; t = (0:fs*8-1)'/fs;
%       x = sin(2*pi*8*t) + sin(2*pi*60*t);
%       clean = notch_lfp(x, fs, 60, 2);
%
%   Notch filtering can distort nearby oscillations and transients.
    validateattributes(signal, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    if nargin < 3 || isempty(center_hz), center_hz = 60; end
    if nargin < 4 || isempty(bandwidth_hz), bandwidth_hz = 2; end

    validateattributes(center_hz, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(bandwidth_hz, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    edge_hz = center_hz + [-1 1]*bandwidth_hz/2;
    assert(edge_hz(1) > 0 && edge_hz(2) < srate/2, ...
        'Stopband must lie inside (0, Nyquist)');

    was_row = isrow(signal);
    if isvector(signal)
        x = double(signal(:));
    else
        x = double(signal);
    end
    assert(size(x, 1) > 30, 'Too few samples for zero-phase filtering');

    [z, p, k] = butter(2, edge_hz/(srate/2), 'stop');
    [sos, g] = zp2sos(z, p, k);
    filtered = filtfilt(sos, g, x);
    if was_row, filtered = filtered.'; end
end

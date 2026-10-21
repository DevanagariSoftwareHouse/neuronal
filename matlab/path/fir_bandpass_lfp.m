function filtered = fir_bandpass_lfp(signal, srate, band_hz, order, beta)
%FIR_BANDPASS_LFP Zero-phase Kaiser-window FIR bandpass for LFP.
%   FILTERED = fir_bandpass_lfp(SIGNAL, SRATE, BAND_HZ, ORDER, BETA)
%   SIGNAL is samples-by-channels; vectors retain their orientation.
%   BAND_HZ = [LOW HIGH], in Hz; ORDER defaults to 200 (even).
%   BETA controls Kaiser sidelobe attenuation (default 8).
%   Uses FIR1, KAISER and FILTFILT (Signal Processing Toolbox).
%
%   Example:
%       fs = 500; t = (0:fs*8-1)'/fs;
%       x = sin(2*pi*8*t) + sin(2*pi*80*t);
%       theta = fir_bandpass_lfp(x, fs, [4 12], 100, 8);
%
%   Zero-phase filtering is noncausal. Discard edge transients.
    validateattributes(signal, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(band_hz, {'numeric'}, ...
        {'vector', 'numel', 2, 'finite', 'positive', 'increasing'});
    assert(band_hz(2) < srate/2, 'Band must be below Nyquist');

    if nargin < 4 || isempty(order), order = 200; end
    if nargin < 5 || isempty(beta), beta = 8; end

    validateattributes(order, {'numeric'}, ...
        {'scalar', 'integer', 'positive', 'even'});
    validateattributes(beta, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'});

    was_row = isrow(signal);
    if isvector(signal)
        x = double(signal(:));
    else
        x = double(signal);
    end
    assert(size(x, 1) > 3*order, ...
        'Signal must exceed 3*ORDER samples for filtfilt');

    b = fir1(order, band_hz/(srate/2), 'bandpass', kaiser(order+1, beta));
    filtered = filtfilt(b, 1, x);

    if was_row, filtered = filtered.'; end
end

function [filtered, bands, labels] = filter_bank_lfp(signal, srate, bands, order)
%FILTER_BANK_LFP Zero-phase Butterworth bank for multichannel LFP.
%   [FILTERED, BANDS, LABELS] = filter_bank_lfp(SIGNAL, SRATE, BANDS, ORDER)
%
%   SIGNAL    Samples-by-channels real, finite data (vector supported).
%   SRATE     Sampling rate in Hz.
%   BANDS     Nx2 low/high frequency edges in Hz; default delta/theta/
%             beta/low-gamma/high-gamma, limited to Nyquist.
%   ORDER     Butterworth prototype order, default 4.
%
%   FILTERED  Samples-by-channels-by-bands, even for single-channel input.
%   BANDS     Actual included bands (Hz).
%   LABELS    Cell array of the corresponding default names, or band names.
%
%   Zero-phase filtering uses BANDPASS_LFP and requires Signal Processing
%   Toolbox. Avoid interpreting filter edge transients as biological events.
%
%   Example:
%       fs = 500;
%       t  = (0:fs*6-1)' / fs;
%       x  = [sin(2*pi*8*t), sin(2*pi*40*t)];
%       [y, hz, labels] = filter_bank_lfp(x, fs);
%       plot(t, y(:, 1, strcmp(labels, 'theta')));
%
%   See also BANDPASS_LFP, WAVELET_SPECTROGRAM.

    validateattributes(signal, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});

    if nargin < 3 || isempty(bands)
        defaults = [1 4; 4 12; 13 30; 30 55; 65 100];
        names    = {'delta', 'theta', 'beta', 'low_gamma', 'high_gamma'};
        selected = defaults(:, 2) < srate / 2;
        bands    = defaults(selected, :);
        labels   = names(selected);
        assert(~isempty(bands), ...
            'No default frequency band lies below Nyquist');
    else
        labels = arrayfun(@(k) sprintf('band_%d', k), ...
            1:size(bands, 1), 'UniformOutput', false);
    end
    if nargin < 4 || isempty(order)
        order = 4;
    end

    validateattributes(bands, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    assert(size(bands, 2) == 2 ...
        && all(bands(:, 1) > 0) ...
        && all(bands(:, 1) < bands(:, 2)) ...
        && all(bands(:, 2) < srate/2), ...
        'Each frequency band must lie strictly within (0, Nyquist)');

    if isvector(signal)
        x = double(signal(:));
    else
        x = double(signal);
    end

    [n, channels] = size(x);
    filtered = zeros(n, channels, size(bands, 1));

    for band = 1:size(bands, 1)
        for ch = 1:channels
            filtered(:, ch, band) = bandpass_lfp( ...
                x(:, ch), srate, bands(band, :), order);
        end
    end
end

function [power, frequency, time, coefficient, coi] = wavelet_spectrogram(signal, srate, frequencies, cycles)
%WAVELET_SPECTROGRAM Complex Morlet time-frequency power for LFP signals.
%   [POWER, FREQUENCY, TIME, COEFFICIENT, COI] = ...
%       wavelet_spectrogram(SIGNAL, SRATE, FREQUENCIES, CYCLES)
%
%   SIGNAL        Samples-by-channels real, finite array (or a vector).
%   SRATE         Sampling frequency in Hz.
%   FREQUENCIES   Positive frequencies in Hz, strictly below Nyquist.
%                 Default: 40 logarithmically spaced bins from 2 to 100 Hz,
%                 clipped to < Nyquist.
%   CYCLES        Scalar or one value per frequency (default 6).
%
%   POWER         Frequencies-by-samples-by-channels |COEFFICIENT|.^2.
%   FREQUENCY     Column vector in Hz.
%   TIME          Column vector in seconds.
%   COEFFICIENT   Complex Morlet coefficient (same dimensions as POWER).
%   COI           Logical validity mask, frequencies-by-samples; false where
%                 the truncated wavelet kernel overlaps signal boundaries.
%
%   POWER is wavelet energy in the normalization of MORLET_WAVELET, not
%   calibrated density per Hz. Exclude ~COI from inference.
%
%   Example:
%       fs = 500;
%       t = (0:fs*10-1)' / fs;
%       x = sin(2*pi*8*t) + sin(2*pi*40*t);
%       [p, f, ts, ~, valid] = wavelet_spectrogram(x, fs, 2:2:90);
%       p(~valid) = NaN;
%       imagesc(ts, f, 10*log10(max(p, eps)));
%       axis xy; xlabel('Time (s)'); ylabel('Frequency (Hz)');
%
%   See also MORLET_WAVELET, WAVELET_COHERENCE, BANDPASS_LFP.

    validateattributes(signal, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});

    if nargin < 3 || isempty(frequencies)
        hi = min(100, 0.9 * srate / 2);
        assert(hi > 2, 'Sampling rate is too low for default frequencies');
        frequencies = logspace(log10(2), log10(hi), 40);
    end
    if nargin < 4 || isempty(cycles)
        cycles = 6;
    end

    if isvector(signal)
        x = double(signal(:));
    else
        x = double(signal);
    end

    frequency = double(frequencies(:));
    validateattributes(frequency, {'double'}, ...
        {'vector', 'real', 'finite', 'positive', 'nonempty'});
    assert(all(frequency < srate / 2), ...
        'Frequencies must be strictly below Nyquist');

    if isscalar(cycles)
        cycles = repmat(cycles, numel(frequency), 1);
    else
        cycles = cycles(:);
    end
    assert(numel(cycles) == numel(frequency) ...
        && all(isfinite(cycles) & cycles >= 3), ...
        'Cycles must be a scalar or one value >= 3 per frequency');

    [n, channels] = size(x);
    nf = numel(frequency);
    assert(double(n) * double(nf) * double(channels) <= 2e7, ...
        'Requested transform exceeds the 20-million-coefficient safety limit');

    time        = (0:n-1)' / srate;
    coefficient = complex(zeros(nf, n, channels));
    coi         = false(nf, n);

    for k = 1:nf
        sigma = cycles(k) / (2*pi*frequency(k));
        edge  = ceil(3.5*sigma*srate);

        if 2*edge < n
            coi(k, edge+1:n-edge) = true;
        end

        for ch = 1:channels
            coefficient(k, :, ch) = morlet_wavelet( ...
                x(:, ch), srate, frequency(k), cycles(k));
        end
    end

    power = abs(coefficient).^2;
end

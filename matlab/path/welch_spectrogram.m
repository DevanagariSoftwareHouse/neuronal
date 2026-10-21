function [power, frequency, time] = welch_spectrogram(signal, srate, window_seconds, overlap_fraction)
%WELCH_SPECTROGRAM Sliding Hann-window single-segment periodograms.
%   [POWER, FREQUENCY, TIME] = welch_spectrogram(X, FS, WINDOW, OVERLAP)
%   X is samples-by-channels. POWER is frequencies-by-windows-by-channels.
%   Unlike WELCH_PSD, this function preserves individual time windows.
%   Each time column is a periodogram, not an average of Welch segments.
%   Window overlap defaults to 0.5; window length defaults to 1 second.
%   Returns one-sided power spectral density (units squared per Hz).
%
%   Example:
%       fs = 500; t = (0:fs*8-1)'/fs;
%       x = sin(2*pi*8*t) + sin(2*pi*40*t);
%       [p, f, tc] = welch_spectrogram(x, fs, 1, 0.75);
%       imagesc(tc, f, 10*log10(max(p, eps))); axis xy;
%
%   See also WELCH_PSD, MULTITAPER_SPECTROGRAM, WAVELET_SPECTROGRAM.
    validateattributes(signal, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});

    if nargin < 3 || isempty(window_seconds), window_seconds = 1; end
    if nargin < 4 || isempty(overlap_fraction), overlap_fraction = 0.5; end

    validateattributes(window_seconds, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(overlap_fraction, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>=', 0, '<', 1});

    if isvector(signal)
        x = double(signal(:));
    else
        x = double(signal);
    end

    [n, nch] = size(x);
    win = round(window_seconds*srate);
    assert(win >= 16 && win <= n, ...
        'Window requires at least 16 samples and must fit recording');
    step = max(1, round(win*(1-overlap_fraction)));
    starts = 1:step:(n-win+1);
    nfft = max(256, 2^nextpow2(win));
    nf = nfft/2+1;
    assert(double(nf)*double(numel(starts))*double(nch) <= 2e7, ...
        'Spectrogram exceeds 20-million-element safety limit');

    window = hann(win, 'periodic');
    frequency = (0:nfft/2)'*srate/nfft;
    time = (starts(:)-1+(win-1)/2)/srate;
    power = zeros(nf, numel(starts), nch);

    for ch = 1:nch
        for j = 1:numel(starts)
            segment = x(starts(j):starts(j)+win-1, ch);
            power(:, j, ch) = periodogram( ...
                segment, window, nfft, srate, 'psd');
        end
    end
end

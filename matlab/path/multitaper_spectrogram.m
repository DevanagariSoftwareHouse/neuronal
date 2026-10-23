function [power, frequency, time] = multitaper_spectrogram(signal, srate, window_seconds, overlap_fraction, time_bandwidth, tapers)
%MULTITAPER_SPECTROGRAM Time-resolved Thomson multitaper PSD in power/Hz.
%   [POWER, FREQUENCY, TIME] = multitaper_spectrogram( ...
%       SIGNAL, SRATE, WINDOW_SECONDS, OVERLAP_FRACTION, ...
%       TIME_BANDWIDTH, TAPERS)
%
%   SIGNAL: samples-by-channels (vector accepted).
%   Defaults: window 1 s, overlap 0.5, NW=3, K=floor(2*NW-1).
%   POWER: frequencies-by-windows-by-channels, one-sided PSD/Hz.
%   FREQUENCY: Hz, TIME: window-center seconds.
%   Uses DPSS and PERIODOGRAM (Signal Processing Toolbox).
%
%   Example:
%       fs = 500; t = (0:fs*10-1)'/fs;
%       x = sin(2*pi*8*t) + 0.1*randn(size(t));
%       [p, f, tc] = multitaper_spectrogram(x, fs, 1, .75, 3, 5);
%       imagesc(tc, f, 10*log10(max(p, eps))); axis xy;
%
%   Adjacent overlapping windows are correlated; do not regard them as
%   statistically independent replicates.
    validateattributes(signal, {'numeric'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    if nargin < 3 || isempty(window_seconds), window_seconds = 1; end
    if nargin < 4 || isempty(overlap_fraction), overlap_fraction = .5; end
    if nargin < 5 || isempty(time_bandwidth), time_bandwidth = 3; end
    if nargin < 6 || isempty(tapers), tapers = floor(2*time_bandwidth-1); end
    validateattributes(window_seconds, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(overlap_fraction, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>=', 0, '<', 1});
    validateattributes(time_bandwidth, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>', 1});
    validateattributes(tapers, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});
    assert(tapers < 2*time_bandwidth, 'Require K < 2*NW');

    if isvector(signal)
        x = double(signal(:));
    else
        x = double(signal);
    end
    [n, nch] = size(x);
    win = round(window_seconds*srate);
    assert(win >= 16 && win <= n, ...
        'Window requires >=16 samples and must fit the recording');
    step = max(1, round(win*(1-overlap_fraction)));
    starts = 1:step:(n-win+1);
    nfft = max(256, 2^nextpow2(win));
    nwins = numel(starts);
    nf = nfft/2+1;
    assert(double(nf)*double(nwins)*double(nch) <= 2e7, ...
        'Spectrogram exceeds 20-million-element safety limit');
    w = dpss(win, time_bandwidth, tapers);
    power = zeros(nf, nwins, nch);
    frequency = (0:nfft/2)'*srate/nfft;
    time = (starts(:)-1+(win-1)/2)/srate;

    for ch = 1:nch
        for j = 1:nwins
            segment = x(starts(j):starts(j)+win-1, ch);
            acc = zeros(nf, 1);
            for k = 1:tapers
                acc = acc + periodogram(segment, w(:, k), nfft, srate, 'psd');
            end
            power(:, j, ch) = acc/tapers;
        end
    end
end

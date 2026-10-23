function test_spectral_extensions()
%TEST_SPECTRAL_EXTENSIONS Synthetic filtering and multitaper regression.
    base = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(base, 'path'));
    rng(37);
    fs = 500;
    t  = (0:fs*10-1)'/fs;
    theta = sin(2*pi*8*t);
    line  = sin(2*pi*60*t);
    x = theta + line;

    fir = fir_bandpass_lfp(x, fs, [6 12], 100);
    cleaned = notch_lfp(x, fs, 60, 2);
    assert(isequal(size(fir), size(x)));
    assert(isequal(size(cleaned), size(x)));
    interior = (fs+1):(numel(x)-fs);
    assert(abs(theta(interior)'*fir(interior)) > ...
        3*abs(line(interior)'*fir(interior)));
    assert(abs(theta(interior)'*cleaned(interior)) > ...
        3*abs(line(interior)'*cleaned(interior)));

    [p, f, tc] = multitaper_spectrogram([theta x], fs, 1, .5, 3, 5);
    assert(size(p, 3) == 2);
    assert(size(p, 2) == numel(tc));
    assert(size(p, 1) == numel(f));
    [~, idx] = min(abs(f-8));
    [~, away] = min(abs(f-25));
    assert(mean(p(idx, :, 1)) > mean(p(away, :, 1)));

    [w, fw] = wavelet_spectrogram(theta, fs, [8 20 40], [4 6 8]);
    assert(isequal(size(w), [3 numel(t)]));
    assert(numel(fw) == 3);
    fprintf('spectral extensions tests passed\n');
end

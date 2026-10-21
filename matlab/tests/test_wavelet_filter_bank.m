function test_wavelet_filter_bank()
%TEST_WAVELET_FILTER_BANK Synthetic contract and frequency-localization tests.
    base = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(base, 'path'));

    rng(71);
    fs = 500;
    t  = (0:fs*8-1)' / fs;
    x  = sin(2*pi*8*t) + 0.8*sin(2*pi*42*t);

    [power, f, ts, coefficients, valid] = ...
        wavelet_spectrogram(x, fs, [8 20 42], 6);

    assert(isequal(size(power), [3 numel(t)]));
    assert(isequal(size(coefficients), size(power)));
    assert(isequal(size(valid), [3 numel(t)]));
    assert(numel(f) == 3 && numel(ts) == numel(t));

    core = valid(1, :) & valid(3, :);
    assert(any(core));
    assert(mean(power(1, core)) > mean(power(2, core)));
    assert(mean(power(3, core)) > mean(power(2, core)));

    [filtered, bands, labels] = filter_bank_lfp( ...
        [x, 0.5*x], fs, [6 10; 35 50]);

    assert(isequal(size(filtered), [numel(t), 2, 2]));
    assert(isequal(size(bands), [2 2]));
    assert(numel(labels) == 2);

    theta = filtered(:, 1, 1);
    gamma = filtered(:, 1, 2);
    assert(abs(theta'*sin(2*pi*8*t)) > abs(theta'*sin(2*pi*42*t)));
    assert(abs(gamma'*sin(2*pi*42*t)) > abs(gamma'*sin(2*pi*8*t)));

    fprintf('wavelet filter-bank tests passed\n');
end

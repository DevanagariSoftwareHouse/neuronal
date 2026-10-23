function test_spectral_methods_comparison()
%TEST_SPECTRAL_METHODS_COMPARISON Reproducible estimator-contract checks.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'path'));
    fs = 500;
    t = (0:fs*10-1)'/fs;
    x = sin(2*pi*8*t) + 0.5*sin(2*pi*42*t);

    [pw, fw, tw] = welch_spectrogram(x, fs, 1, .5);
    [pm, fm, tm] = multitaper_spectrogram(x, fs, 1, .5, 3, 5);
    assert(isequal(size(pw), size(pm)));
    assert(isequal(fw, fm) && isequal(tw, tm));
    assert(all(isfinite(pw(:))) && all(pw(:) >= 0));
    assert(all(isfinite(pm(:))) && all(pm(:) >= 0));
    [~, eight] = min(abs(fw-8));
    [~, quiet] = min(abs(fw-25));
    assert(mean(pw(eight, :)) > mean(pw(quiet, :)));
    assert(mean(pm(eight, :)) > mean(pm(quiet, :)));

    [pc, fc, tc, ~, mask] = ...
        wavelet_spectrogram(x, fs, [8 25 42], [4 6 8]);
    assert(isequal(size(pc), [3 numel(x)]));
    assert(all(size(mask) == [3 numel(x)]));
    assert(numel(tc) == numel(x) && numel(fc) == 3);
    assert(any(mask(1, :)) && any(mask(3, :)));
    core = mask(1, :) & mask(2, :) & mask(3, :);
    assert(mean(pc(1, core)) > mean(pc(2, core)));
    assert(mean(pc(3, core)) > mean(pc(2, core)));
    fprintf('spectral methods comparison tests passed\n');
end

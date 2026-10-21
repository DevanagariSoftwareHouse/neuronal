function test_tortlab_minimal_macro()
%TEST_TORTLAB_MINIMAL_MACRO Synthetic regression checks of Tortlab-inspired API.
% Run after addpath('matlab/path'); requires Signal Processing Toolbox.

    rng(11);
    n = 4000;
    fs = 500;
    t = (0:n-1)' / fs;

    % Matched 2:1 phase should lock; unrelated random phases should not.
    a = 2*pi*8*t;
    b = 2*a + 0.3;
    [r, phi, d] = phase_phase_coupling(a, b, 2, 1);
    assert(abs(r - 1) < 1e-10);
    assert(abs(angle(exp(1i * (phi + 0.3)))) < 1e-10);
    assert(numel(d) == n);
    rnull = phase_phase_coupling(a, 2*pi*rand(n,1), 2, 1);
    assert(rnull < 0.1);

    % Equal phases yield PLV one in every populated slow-phase bin.
    slow = 2*pi*5*t;
    [plv, centers, counts] = phase_binned_plv(a, a + 0.2, slow, 12, 10);
    assert(all(abs(plv - 1) < 1e-10));
    assert(numel(centers) == 12 && sum(counts) == n);
    [empty, ~, c] = phase_binned_plv(a, a, slow, 12, n);
    assert(all(isnan(empty)) && sum(c) == n);

    % A synthetic narrow-band amplitude modulation yields nonnegative MI.
    x = cos(2*pi*8*t) + (1 + 0.8*cos(2*pi*8*t)) .* cos(2*pi*70*t);
    [mi, fp, fa] = pac_comodulogram(x, fs, [6 10], [60 80], 18);
    assert(isequal(size(mi), [1 1]) && isfinite(mi) && mi >= 0 && mi <= 1);
    assert(fp == 8 && fa == 70);

    % IID count matrix has valid MP eigenvalue statistics.
    counts = double(rand(n,8) < 0.15);
    [sig, edge, lambda] = assembly_mp_significance(counts);
    assert(islogical(sig) && numel(sig) == numel(lambda));
    assert(edge > 1 && all(isfinite(lambda)));
    assert(all(diff(lambda) <= 1e-10));
end

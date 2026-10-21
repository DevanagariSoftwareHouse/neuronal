function test_filter_probe()
%TEST_FILTER_PROBE Matched-kernel linear convolution and FFT regression.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'path'));

    fs = 1000;
    t = (0:fs*3-1)'/fs;
    x = sin(2*pi*80*t);
    r = filter_probe(x, fs, 80, 6);

    assert(isequal(size(r.convolution), size(x)));
    assert(isequal(size(r.fourier), size(x)));
    assert(isequal(size(r.wavelet), size(x)));
    assert(any(r.valid) && ~r.valid(1) && ~r.valid(end));
    assert(r.relative_fft_error < 1e-10, ...
        'FFT multiplication must match linear convolution');
    assert(all(isfinite(r.transfer)));

    probes = filter_compare(x, fs, [50 80 120], [4 6 8]);
    assert(numel(probes) == 3);
    assert(all([probes.relative_fft_error] < 1e-10));

    impulse = zeros(size(x));
    impulse(round(1.5*fs)+1) = 1;
    i = filter_probe(impulse, fs, 80, 6);
    assert(max(abs(i.convolution)) > 0);
    assert(nnz(abs(i.convolution) > 0.1*max(abs(i.convolution))) > 1, ...
        'An impulse must spread under a band-limited kernel');
    fprintf('filter probe tests passed\n');
end

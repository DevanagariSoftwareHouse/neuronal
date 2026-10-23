function test_lfp_basic_filters()
%TEST_LFP_BASIC_FILTERS Verify high/low-pass separation on synthetic tones.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'path'));
    fs = 500;
    t = (0:fs*8-1)' / fs;
    low = sin(2*pi*8*t);
    high = sin(2*pi*70*t);
    x = [low+high, low-high];
    a = lowpass_lfp(x, fs, 20);
    b = highpass_lfp(x, fs, 30);
    assert(isequal(size(a), size(x)) && isequal(size(b), size(x)));
    interior = fs+1:numel(t)-fs;
    assert(abs(low(interior)'*a(interior, 1)) > ...
        5*abs(high(interior)'*a(interior, 1)));
    assert(abs(high(interior)'*b(interior, 1)) > ...
        5*abs(low(interior)'*b(interior, 1)));
    assert(isrow(lowpass_lfp(x(:, 1).', fs, 20)));
    fprintf('basic LFP filter tests passed\n');
end

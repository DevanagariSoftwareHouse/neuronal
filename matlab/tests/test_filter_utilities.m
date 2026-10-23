function test_filter_utilities()
%TEST_FILTER_UTILITIES Synthetic regression for FIR, response, masks, resampling.
    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(root, 'path'));

    fs    = 1000;
    t     = (0:fs*6-1)'/fs;
    slow  = sin(2*pi*8*t);
    fast  = sin(2*pi*120*t);
    noise = sin(2*pi*60*t);
    x     = slow + fast + 0.8*noise;

    [y, b] = fir_filter_lfp(x, fs, 'low', 25, 100, 'kaiser');
    assert(numel(b)==101 && isequal(size(y),size(x)));
    inner = fs+1:numel(t)-fs;
    assert(abs(slow(inner)'*y(inner)) > ...
        8*abs(fast(inner)'*y(inner)));

    r = filter_response(b,1,fs,2048,true);
    assert(numel(r.frequency)==2048);
    assert(all(isfinite(r.magnitude)));
    [mask, margin, residual] = filter_edge_mask(r.impulse,numel(x),1e-3);
    assert(isequal(size(mask),size(x)));
    assert(margin>=0 && residual<=1e-3+1e-10);

    [down, new_fs, ts] = resample_lfp(x,fs,1,2);
    assert(new_fs==500);
    assert(size(down,1)==fs*3 && numel(ts)==numel(down));

    [clean, centers] = line_noise_harmonics(x, fs, 60, 2, 2);
    assert(isequal(centers,[60 120]));
    assert(isequal(size(clean),size(x)));
    assert(abs(noise(inner)'*clean(inner)) < ...
        0.3*abs(noise(inner)'*x(inner)));

    fprintf('filter utilities tests passed\n');
end

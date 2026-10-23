%FILTER_PROBE_DEMO Compare filter kernels on a burst and on an impulse.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'path'));

fs = 1000;
t = (0:fs*3-1)'/fs;
rng(17);
burst = sin(2*pi*80*t).*exp(-.5*((t-1.5)/.04).^2);
impulse = zeros(size(t));
impulse(round(1.5*fs)+1) = 1;
signals = {burst, impulse};
names = {'80 Hz oscillatory burst', 'Single impulse'};

for trial = 1:2
    x = signals{trial};
    r = filter_probe(x, fs, 80, 6);
    figure('Name', names{trial});
    subplot(4,1,1);
    plot(t, x); xlim([1.2 1.8]); title(names{trial});
    subplot(4,1,2);
    plot(r.kernel_time, real(r.kernel), r.kernel_time, imag(r.kernel));
    title('Complex kernel: real and imaginary parts');
    subplot(4,1,3);
    plot(r.frequency, r.transfer); xlim([30 130]);
    title('Magnitude of the kernel transfer function');
    subplot(4,1,4);
    plot(t, abs(r.convolution), ...
         t, abs(r.fourier), '--', ...
         t, abs(r.hilbert), ':', ...
         t, abs(r.wavelet), '-.');
    xlim([1.2 1.8]); xlabel('Time (s)');
    title('Envelopes (different analytic normalizations)');
    legend('Convolution', 'FFT product', 'Hilbert', 'Morlet');
    fprintf('%s: matched FFT error = %.3g\n', ...
        names{trial}, r.relative_fft_error);
end

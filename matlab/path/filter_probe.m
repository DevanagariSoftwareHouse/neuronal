function result = filter_probe(signal, srate, frequency_hz, cycles)
%FILTER_PROBE Compare matched time convolution, FFT, Hilbert and Morlet.
%   RESULT = filter_probe(SIGNAL, SRATE, FREQUENCY_HZ, CYCLES)
%
%   SIGNAL       Real finite vector, sampled at SRATE Hz.
%   FREQUENCY_HZ Gaussian-kernel center, > 0 and below Nyquist.
%   CYCLES       Gaussian envelope duration in oscillation cycles (default 6).
%
%   RESULT contains:
%     time                 Sample times (seconds).
%     kernel_time          Kernel lags (seconds).
%     kernel               Complex, energy-normalized Gaussian/Gabor kernel.
%     convolution          Complex linear convolution, output 'same'.
%     fourier              FFT multiplication with LINEAR zero-padding; same
%                          discrete kernel and cropping as convolution.
%     hilbert              Analytic signal of 2*real(convolution), with
%                          Fourier-domain Hilbert transform.
%     wavelet              MORLET_WAVELET result (near, but not necessarily
%                          identical: admissibility correction differs).
%     frequency            One-sided FFT frequency grid (Hz).
%     transfer             Magnitude of kernel FFT at frequency.
%     valid                Logical mask excluding truncated-kernel edges.
%     relative_fft_error   Relative max difference FFT vs convolution.
%     note                 Methodological limitations.
%
%   The matched convolution/FFT paths should agree up to floating-point
%   roundoff. Hilbert and Morlet need NOT match exactly; Hilbert imposes
%   a positive-frequency analytic projection and Morlet includes a
%   zero-mean admissibility correction. Their envelopes can differ.
%   No filtered transient alone proves a physiological oscillator.
%
%   Example:
%       fs = 1000; t = (0:fs*4-1)'/fs;
%       x = sin(2*pi*40*t) + 0.5*sin(2*pi*85*t);
%       r = filter_probe(x, fs, 40, 6);
%       plot(r.time, abs(r.convolution), r.time, abs(r.fourier));
%
%   See also MORLET_WAVELET, ANALYTIC_PHASE, FILTER_COMPARE.
    if nargin < 4 || isempty(cycles), cycles = 6; end

    validateattributes(signal, {'numeric'}, ...
        {'vector', 'real', 'finite', 'nonempty'});
    validateattributes(srate, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(frequency_hz, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'});
    validateattributes(cycles, {'numeric'}, ...
        {'scalar', 'real', 'finite', '>=', 3});
    assert(frequency_hz < srate/2, 'Center must lie below Nyquist');

    x = double(signal(:));
    n = numel(x);
    sigma = cycles/(2*pi*frequency_hz);
    radius = ceil(3.5*sigma*srate);
    lag = (-radius:radius)'/srate;

    kernel = exp(-lag.^2/(2*sigma^2)).*exp(1i*2*pi*frequency_hz*lag);
    kernel = kernel/sqrt(sum(abs(kernel).^2));
    m = numel(kernel);
    assert(double(n)+double(m)-1 <= 2e7, ...
        'Requested convolution exceeds the allocation safety limit');

    % Full linear convolution followed by MATLAB's 'same' center crop.
    full_time = conv(x, kernel, 'full');
    first = floor(m/2)+1;
    y_time = full_time(first:first+n-1);

    % Zero padding avoids the circular convolution error of raw FFT(x).*FFT(h).
    nfft = 2^nextpow2(n+m-1);
    full_fft = ifft(fft(x, nfft).*fft(kernel, nfft));
    y_fft = full_fft(first:first+n-1);

    % The Hilbert projection of the REAL kernel result is a separate
    % analytic representation, not simply another way to apply kernel.
    y_hilbert = hilbert(2*real(y_time));
    y_wavelet = morlet_wavelet(x, srate, frequency_hz, cycles);

    valid = false(n, 1);
    if 2*radius < n
        valid(radius+1:n-radius) = true;
    end

    fgrid = (0:floor(nfft/2))'*srate/nfft;
    transfer_fft = fft(kernel, nfft);
    transfer = abs(transfer_fft(1:numel(fgrid)));

    result.time               = (0:n-1)'/srate;
    result.kernel_time        = lag;
    result.kernel             = kernel;
    result.convolution        = y_time;
    result.fourier            = y_fft;
    result.hilbert            = y_hilbert;
    result.wavelet            = y_wavelet(:);
    result.frequency          = fgrid;
    result.transfer           = transfer;
    result.valid              = valid;
    result.relative_fft_error = max(abs(y_time-y_fft)) ...
        /max(max(abs(y_time)), eps);
    result.note = ['Only time convolution and FFT use exactly identical ' ...
        'kernels. Hilbert and Morlet are comparisons with distinct ' ...
        'analytic/admissibility conventions. Mask invalid edges.'];
end

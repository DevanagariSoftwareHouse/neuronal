# Filter probes: Fourier, Hilbert and wavelet

Inspired by Bruns (2004), *Fourier-, Hilbert- and wavelet-based signal
analysis: are they really different approaches?*, DOI
10.1016/j.jneumeth.2004.03.002; and de Cheveigné & Nelken (2019),
*Filters: When, Why, and How (Not) to Use Them*, DOI
10.1016/j.neuron.2019.02.039.

## Which file should I call?

The `matlab/path/filter_*.m` prefix is reserved for **signal-filter
diagnostics / filter banks**. Other filtering operations retain their
established descriptive names; `coupling_filters.m` fits a GLM and
does **not** filter LFP. Preserve existing function signatures.

- `filter_probe(x, fs, f0, cycles)`: returns kernel, transfer response,
  four complex outputs, exact-convolution-vs-FFT numerical error and
  a conservative boundary-validity mask.
- `filter_compare(x, fs, frequencies, cycles)`: array of probes, one
  per center frequency. Parameter matching is explicit.
- `filter_bank_lfp(x, fs, bands, order)`: conventional Butterworth
  LFP filter bank, not interchangeable with complex Morlet kernels.
- `bandpass_lfp`, `fir_bandpass_lfp`, `lowpass_lfp`,
  `highpass_lfp`, `notch_lfp`: real filtering with documented cutoffs.
- `analytic_phase`: Hilbert complex analytic signal of a prefiltered
  vector; `morlet_wavelet` and `wavelet_spectrogram`: complex wavelet
  coefficients without a prerequisite bandpass.

## Exactly equal versus comparable

`filter_probe` constructs a **finite complex Gaussian-modulated kernel**
and uses it for both (1) full linear time-domain convolution with
center crop, and (2) multiplication of padded FFTs with the same crop.
Those paths are numerically equal to floating-point precision.
No ideal rectangular FFT filter is used.

`hilbert` applies an analytic-signal projection to the real
output of that kernel. Since this Gaussian-modulated kernel is not
perfectly one-sided, the Hilbert result is not guaranteed equal to
the complex convolution. `morlet_wavelet` uses a zero-mean
admissibility correction not applied to the plain Gabor kernel, so
wavelet equality is **also not assumed**. For a narrow-band sinusoid,
the Hilbert reconstruction approximately retains the complex convolution's
envelope amplitude; no extra factor of two is applied. Inspect both
envelopes and phase, and normalize explicitly when comparing Morlet kernels.

## Experiments

Run `matlab/examples/filter_probe_demo.m`. It deliberately contrasts
a real oscillatory 80 Hz burst with a single nonoscillatory impulse:
both produce a localized oscillatory-looking filter response.
Plot kernels, transfer response and envelopes. To use the toolbox
on multiple frequencies:

```matlab
fs = 1000;
t = (0:fs*3-1)'/fs;
x = sin(2*pi*80*t);
results = filter_compare(x, fs, [40 80 120], [4 6 8]);
```

The returned `valid` mask excludes kernel overlaps at recording edges.
It is **not** a statistical detection mask or cone-of-influence
confidence interval. A passband output is not evidence of a genuine
neuronal rhythm without suitable raw-signal, transient and null controls.

## Scientific caveats

- Effective bandwidth, normalization, forward/backward filtering,
  padding and boundary handling are part of the estimator definition.
- A narrow filter response produces a longer response to transients.
- Avoid cascades of filters without measuring their aggregate
  transfer and impulse responses.
- Hilbert envelopes are defined for the specified filtered signal;
  wavelet amplitudes are not necessarily numerically identical.
- Do not equate sample spacing with time-frequency resolution.
- Use sufficiently high original acquisition sampling rates for
  high-frequency ripple studies, not merely an upsampled LFP.
- MATLAB Signal Processing Toolbox is needed for `hilbert`.

# Spectra, oscillations and band-limited events (MATLAB)

The primitives in `path/` separate **spectral estimation**, **spectral
parameterisation**, **time-frequency decomposition**, **cycle and episode
description**, and **candidate event screening**. All inputs are finite
real vectors sampled at `srate` Hz from time zero; frequencies are Hz,
phase radians. The CON²PHYS LFP is 500 Hz (Nyquist 250 Hz). Process
bounded blocks of channels and time: most functions hold the whole input
and some intermediate copies in memory.

Several outputs here are **event sources** for
[06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md): phase, envelope, cycle
onsets, oscillatory episodes and ripple candidates.

## 1. Power spectra

```matlab
fs = 500;
x = double(neuronal_read(m, 1:30*fs, 7));        % 30 s, one channel
[f, p] = welch_psd(x, fs, 4, .5);                 % 4 s Hann, 50% overlap
[fm, pm] = multitaper_psd(x(1:4*fs), fs, 3);      % NW = 3, K = 5 tapers
plot(f, 10*log10(p))
```

`welch_psd` uses periodic Hann windows of `round(window_seconds*fs)`
samples (at least 8, default 4 s), `floor(n*overlap)` overlap (default 0.5)
and `pwelch` with `max(256, 2^nextpow2(n))` FFT points; the result is a
one-sided PSD in units^2/Hz. `multitaper_psd` averages DPSS periodograms
over the **whole input** (no segmentation, no adaptive weights), with
`1 <= tapers < 2*NW` and default `floor(2*NW-1)`. Adjacent bins are not
independent observations, and a long record is better summarised by
averaging segments than by one multitaper over millions of samples.

## 2. Aperiodic background and peak candidates

```matlab
bg = aperiodic_slope(f, p, [2 180], [48 52; 58 62]);   % fit band, exclusions
peaks = spectral_peak_candidates(f, p, 10, 3);          % width Hz, prominence dB
[fi, fractal, osc, total] = irasa_decomposition(x, fs, 4, 1.1:.1:1.9);
H = spectral_entropy(p(f >= 1 & f <= 100));
```

`aperiodic_slope` fits a line to `log10 p` against `log10 f` inside the fit
band, after removing exclusion bands, and returns `slope`, `exponent`
(= -slope), `intercept`, `background`, `fit_mask` and a `note`. Peaks must
be excluded explicitly; this is **not** FOOOF/specparam.
`spectral_peak_candidates` subtracts a moving median (window `width_hz`)
from the dB spectrum and keeps `findpeaks` maxima of the excess above
`prominence_db`, as a table of `frequency_hz`, `excess_db`, `power`.
`irasa_decomposition` takes the median over resampling factors `h` in
`(1,2)` of the geometric mean of up- and down-resampled Welch spectra as the
fractal part, and `max(0, total - fractal)` as the oscillatory part; it is
valid only below `fs/(2*max h)` but returns every bin to Nyquist.
`spectral_entropy` is the Shannon entropy of the normalised PSD divided by
`log(numel)`, in `[0,1]`; it depends on the band and bin count and does not
measure physiological complexity.

## 3. Phase, envelope and wavelets

```matlab
theta = bandpass_lfp(x, fs, [6 10]);               % see 02_PREPROCESSING.md
[phase, amp, z] = analytic_phase(theta);
[c8, t_s] = morlet_wavelet(x, fs, 8, 6);           % 8 Hz, 6 cycles
power8 = abs(c8).^2;
```

`analytic_phase` is `hilbert` of a real vector: phase in radians, amplitude
in input units, and the complex analytic signal. Phase is meaningful only
for a band-limited input and away from filter edges. `morlet_wavelet`
convolves with a unit-energy complex Morlet (`cycles >= 3`, default 6;
`sigma = cycles/(2*pi*f)`, support +/-3.5 sigma) and returns coefficients on
the input time axis `t_s = (k-1)/fs`. Samples within the support of either
edge are contaminated; `bosc_detect` excludes them explicitly.

## 4. Cycles and adaptive decompositions

```matlab
cycles = cycle_by_cycle(theta(valid), fs);         % onset_s relative to the crop
pe = permutation_entropy(x(1:10*fs), 3, 1);
[imfs, residual] = empirical_mode_decomposition(x(1:5*fs), 5, 40, .05);
rng(17)
[eimfs, eres] = ensemble_empirical_mode_decomposition(x(1:5*fs), 20, .2, 5);
```

`cycle_by_cycle` segments a prefiltered oscillation between successive
upward zero crossings and reports `onset_s`, `period_s`, `frequency_hz`
and `half_peak_to_peak`; times are relative to the first input sample. It
omits the burst and quality criteria of `bycycle`.
`permutation_entropy` counts ordinal patterns of `order` 2..7 at integer
`delay`, excludes tied patterns, and normalises by `log(order!)`.
`empirical_mode_decomposition` sifts with PCHIP envelopes anchored at the
endpoints and a squared-difference stopping ratio; columns of `imfs` plus
`residual` reconstruct the input. `ensemble_empirical_mode_decomposition`
averages modes by extraction index over noise realisations and uses the
global random stream: seed it outside. Both are exploratory: mode mixing,
endpoint artifacts and stopping-rule bias need inspection.

## 5. Oscillatory episodes (BOSC)

```matlab
res = bosc_detect(x(1:60*fs), fs, 4:2:30, .95, 3, 6);
k = find(res.frequency_hz == 8);
episodes_8hz = res.episodes{k};                    % start_s, stop_s, duration_s, cycles
[ep, mask, fraction] = oscillation_episode( ...
    res.wavelet_power(k,:) > res.power_threshold(k) & res.valid_mask(k,:), fs, 8, 3);
```

`bosc_detect` computes Morlet power for at least three ascending
frequencies, fits a global log-log background to the mean power,
thresholds at the `probability` quantile of an exponential (chi-square,
2 df) marginal, and keeps runs longer than `minimum_cycles`. Inputs are
capped at 4e6 frequency x time values. Outputs include `wavelet_power`,
`background_power`, `power_threshold`, `detected_mask`, `valid_mask`,
`p_episode`, per-frequency `episodes` tables and a `note`.
`oscillation_episode` is the duration step alone: maximal runs of a binary
vector lasting at least `ceil(cycles*fs/f)` samples. The background is
fitted to power that includes the oscillations, so the threshold is raised
near true peaks; the per-sample probability is not an episode false-positive
rate. This is **not** eBOSC.

## 6. Envelope moments and ripple candidates

```matlab
mom = lfp_envelope_moments(block_channels_by_samples, fs, ...
    'WindowSeconds', 10, 'StepSeconds', 1, 'TimeOriginSeconds', 0);
plot(mom.time_seconds, mom.mean(:,1,1))            % theta envelope, channel 1

ripples = ripple_candidate_events(x_broadband, fs_broadband);   % 120..200 Hz
```

`lfp_envelope_moments` takes **channels x samples** and returns mean,
population variance, skewness and excess kurtosis of theta (4-12 Hz), beta
(13-30 Hz) and gamma (30-80 Hz) Hilbert envelopes in complete sliding
windows, as **windows x channels x bands** arrays with window times,
channel validity and edge flags; overlapping windows are dependent (see the
function help for every option).
`ripple_candidate_events` bandpasses, takes the Hilbert envelope and a
robust z-score `(a - median)/(1.4826 MAD)`, and keeps runs above `onset_z`
(default 2) lasting 25-150 ms whose maximum exceeds `peak_z` (default 5),
excluding runs that touch either edge. The table holds `start_s`,
`stop_s`, `duration_s`, `peak_robust_z` and `peak_s`. The default band
needs `fs > 400` Hz; on 500 Hz LFP pass a band below 0.45 fs and call the
result high-frequency candidates, not sharp-wave ripples.

## Tests

From the repository root:

```matlab
run('matlab/tests/smoke_arsenal.m')            % spectra, phase, wavelet, cycles, EMD, ripples
run('matlab/tests/smoke_bosc_circ_glm.m')      % BOSC and episodes
run('matlab/tests/test_lfp_envelope_moments.m')
run('matlab/tests/check_arsenal_identities.m') % aperiodic fit, entropy, EMD identities
```

Synthetic sinusoids and noise check shapes, peak locations and
reconstruction. None of them validates a neural oscillation; see
[12_REVIEW.md](12_REVIEW.md) for open BOSC and IRASA items.

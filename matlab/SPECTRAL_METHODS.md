# Spectral estimation: complementary methods

The MATLAB package exposes three time-resolved methods with deliberately
different assumptions. Choose a method based on the scientific question,
rather than interpreting pixel intensity as comparable across estimators.

| Function | Estimator | Units | Resolution |
|---|---|---|---|
| `welch_spectrogram` | Sliding Hann-window periodogram | power/Hz | Fixed window |
| `multitaper_spectrogram` | Averaged DPSS-tapered periodograms | power/Hz | Fixed window; NW/K control smoothing |
| `wavelet_spectrogram` | Complex Morlet squared modulus | wavelet-energy units | Frequency-dependent kernel |
| `welch_psd` | Welch average of overlapping windows | power/Hz | Whole selected segment |
| `multitaper_psd` | DPSS averaged PSD | power/Hz | Whole selected segment |

## A reproducible example

Run `matlab/examples/spectral_methods_comparison.m`. It creates 8 Hz
theta plus a localized 42 Hz gamma burst and plots all three methods.

The wavelet's frequency-dependent kernel generally provides a more
flexible tradeoff across frequencies. Change `cycles` to adjust temporal
versus frequency smoothing; a vector of cycles must align with the supplied
frequencies. Frequencies must lie below Nyquist.

## Interpretation and cautions

- Sliding periodograms and multitaper spectrograms return PSD per Hz;
  the current Morlet squared coefficients are *not* PSD-normalized.
- `10*log10(power)` gives a dB representation relative to an implicit
  unit reference, not a cross-method absolute scale.
- Suppress `~coi` in the Morlet result. The mask identifies boundaries
  where the truncated kernel overlaps unavailable observations, and is
  not a probabilistic confidence interval.
- Both filtering and wavelets can spread brief artifacts in time.
- Adjacent spectrogram columns, particularly overlapped windows, are
  statistically dependent. Neither windows nor frequency bins can
  automatically serve as independent replicates.
- Inspect waveform shape, line noise, referencing, stationarity and
  trial/animal nesting before interpreting a physiological oscillation.
- The current functions require MATLAB Signal Processing Toolbox and
  use finite real-valued inputs.
- `multitaper_spectrogram` uses equal taper weights, not adaptive
  Thomson weighting or confidence intervals.

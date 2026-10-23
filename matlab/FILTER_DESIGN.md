# Filter design and diagnostics (MATLAB)

The `matlab/path` family provides complementary operations rather than
one mandatory preprocessing chain. This guide follows Bruns (2004), DOI
10.1016/j.jneumeth.2004.03.002 and de Cheveigné & Nelken (2019), DOI
10.1016/j.neuron.2019.02.039.

| Function | Inputs | Outputs | Intended purpose |
|---|---|---|---|
| `fir_filter_lfp` | signal, srate, mode, cutoff, order, window | filtered, b | FIR design and zero-phase extraction |
| `filter_response` | b, a, srate, nfft, zero_phase | struct | Magnitude, phase, delay, impulse and step diagnostics |
| `filter_edge_mask` | impulse, n_samples, tolerance | valid, margin, energy_outside | Heuristic edge exclusion from a centered impulse |
| `resample_lfp` | signal, srate, numerator, denominator | output, new_srate, time | Rational polyphase antialiased resampling |
| `line_noise_harmonics` | signal, srate, fundamental, bandwidth, max_harmonics | filtered, centers | Opt-in line interference harmonics |

Run `matlab/examples/filter_design_diagnostics.m` on synthetic data,
then `matlab/tests/test_filter_utilities.m`.

## Kernel and estimator reporting

- Record design, sample rate, exact cutoffs, window type and numerical
  coefficients (if possible), forward/backward application and padding.
- `filter_response(b,a,fs,nfft,true)` uses the ideal infinite-record
  forward/backward transfer `|H|^2`, not an exact finite FILTFILT
  operator near boundaries.
- `filter_edge_mask` requires an odd-length centered impulse. Its
  squared-energy tolerance is a heuristic: it does not guarantee
  a bound on the filtered waveform error from edge artifacts.
- Inspect sharp transients before declaring filtered ringing to be
  physiological rhythmic activity.
- Use `resample_lfp` when changing digital rates; it cannot restore
  information removed by the recording hardware.
- Apply `line_noise_harmonics` only after demonstrating narrowband
  contamination. Notches can remove true activity near 60/120 Hz.
- For 500 Hz sampling, Nyquist is 250 Hz; avoid ripple claims near
  the acquisition antialiasing transition without metadata.

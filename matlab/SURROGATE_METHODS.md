# Surrogate methods (draft implementations)

These functions are **not yet MATLAB-tested or statistically calibrated**.
Choose a generator based on its null hypothesis, not on the statistic alone.
Use `rng(seed)` externally for reproducibility.

| Generator | Null model / preserved features | Limitations |
| --- | --- | --- |
| `phase_randomized_surrogate` | Fourier magnitudes of one stationary real signal | Does not preserve nonstationary structure or marginal distribution |
| `multivariate_phase_surrogate` | Shared phase shifts preserve all cross spectra of simultaneous channels | Not appropriate to destroy interchannel linear coupling |
| `aaft_surrogate` | Approximately preserves marginal and power spectrum | Can have substantial spectral bias |
| `iaaft_surrogate` | Exactly preserves sample values, approximately preserves Fourier amplitudes | Inspect `diagnostics.relative_spectral_error` |
| `interval_jitter_surrogate` | Fixed-window spike counts | May create refractory violations; no pattern preservation |
| `spike_dither_surrogate` | Spike-centered random displacements | Not an exact interval-jitter test |
| `trial_shuffle_surrogate` | Per-trial content, destroys matched trial pairing | Assumes trials exchangeable |
| `block_shuffle_surrogate` | Within-block waveform/order | Nonstationarity and block boundaries require care |
| `local_permutation_surrogate` | Approximate conditioning-state proximity | Heuristic, not guaranteed valid conditional permutation test |

`surrogate_test` uses the plus-one Monte Carlo tail formula. Its nominal
interpretation requires exchangeability under the null; it is not guaranteed
by arbitrary surrogate generators. `surrogate_maxstat_test` computes
familywise adjusted p-values from **joint** surrogate draws.

## Examples

```matlab
rng(42)
x = randn(1000,1);
[y,diag] = iaaft_surrogate(x);
assert(isequal(sort(x),sort(y)))
disp(diag.relative_spectral_error)

rng(42)
spikes = sort(10*rand(100,1));
j = interval_jitter_surrogate(spikes,0.1,0);
assert(isequal(histcounts(spikes,0:0.1:10),histcounts(j,0:0.1:10)))

rng(42)
test = surrogate_test(x,@(z)mean(z.^3),@phase_randomized_surrogate,999,'two-sided');
disp(test.p)
```

## References

- Theiler et al. (1992), doi:10.1016/0167-2789(92)90102-S
- Prichard & Theiler (1994), doi:10.1103/PhysRevLett.73.951
- Schreiber & Schmitz (1996), doi:10.1103/PhysRevLett.77.635
- Kugiumtzis (1999), doi:10.1103/PhysRevE.60.2808
- Amarasingham et al. (2012), doi:10.1152/jn.00633.2011
- Platkiewicz et al. (2017), doi:10.1162/NECO_a_00927
- Shorten et al. (2020), doi:10.1371/journal.pcbi.1008054
- Stella et al. (2022), doi:10.1523/ENEURO.0505-21.2022

## Next steps

Implement and validate pattern jitter, constrained nonstationary surrogates,
trial shifting, cycle surrogates, and conditional TE permutations with
explicit null models. Benchmark Type-I error and power on synthetic data.

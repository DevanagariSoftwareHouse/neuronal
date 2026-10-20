# Surrogate methods (draft implementations)

[Índice](README.md) · [Anterior](09_MODELS_DECODING.md) · [Próximo](11_INFERENCE.md)

These functions are **not yet MATLAB-tested or statistically calibrated**.
Choose a generator based on its null hypothesis, not on the statistic alone.
Use `rng(seed)` externally for reproducibility: every generator below draws
from the global random stream.

A surrogate test has three separate parts, kept in separate functions:
a **generator** that produces one dataset under the null, a **statistic**
supplied by the caller, and a **Monte Carlo tail** (`surrogate_test`,
`surrogate_maxstat_test`). The generator decides what the p-value means.

## 1. Generators and what they preserve

| Generator | Null model / preserved features | Limitations |
| --- | --- | --- |
| `circular_shift_surrogate` | Every sample and the full autocorrelation of one series; breaks alignment to a second series or to events | Deterministic for a given shift; choose shifts beyond the autocorrelation time and away from edges |
| `phase_randomized_surrogate` | Fourier magnitudes of one stationary real signal | Does not preserve nonstationary structure or marginal distribution |
| `multivariate_phase_surrogate` | Shared phase shifts preserve all cross spectra of simultaneous channels | Not appropriate to destroy interchannel linear coupling |
| `aaft_surrogate` | Approximately preserves marginal and power spectrum | Can have substantial spectral bias |
| `iaaft_surrogate` | Exactly preserves sample values, approximately preserves Fourier amplitudes | Inspect `diagnostics.relative_spectral_error` |
| `block_shuffle_surrogate` | Within-block waveform/order (rows are samples, all columns move together) | Nonstationarity and block boundaries require care; the incomplete tail stays in place |
| `interval_jitter_surrogate` | Fixed-window spike counts | May create refractory violations; no pattern preservation |
| `jitter_spike_surrogate` | Same fixed-window uniform jitter | Numerically identical to `interval_jitter_surrogate`; kept for provenance |
| `spike_dither_surrogate` | Spike-centered random displacements | Not an exact interval-jitter test |
| `trial_shuffle_surrogate` | Per-trial content, destroys matched trial pairing | Assumes trials exchangeable |
| `local_permutation_surrogate` | Approximate conditioning-state proximity | Heuristic, not guaranteed valid conditional permutation test |

Signal generators take a vector (row or column, returned in the same
orientation) except `multivariate_phase_surrogate` and
`block_shuffle_surrogate`, which take **samples x channels**. Spike
generators take timestamps in seconds and return them **sorted**.
`trial_shuffle_surrogate` permutes a cell array with one trial per cell.
`local_permutation_surrogate(x, conditioning, k)` replaces each row of `x`
with the row of a random one of its `k` nearest neighbours in the
conditioning space (default `k = min(10, n-1)`).

## 2. Monte Carlo tails

`surrogate_test` uses the plus-one Monte Carlo tail formula
`(1 + #extreme)/(B + 1)` with at least 19 draws (default 999); `'two-sided'`
compares absolute values and therefore assumes a null centred at zero.
Its nominal interpretation requires exchangeability under the null; it is
not guaranteed by arbitrary surrogate generators. `surrogate_maxstat_test`
computes familywise adjusted p-values from **joint** surrogate draws: each
row of `null` must come from one surrogate dataset evaluated at every
feature, so the maximum respects their dependence.

## 3. Examples

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

## 4. Event-locked nulls

```matlab
% Is the spike-triggered LFP average larger than for jittered spikes?
statfun = @(t) max(abs(event_triggered_average(lfp, t, fs, .2, .2)));
jitter = @(t) interval_jitter_surrogate(t, .025, 0);
rng(7)
locking = surrogate_test(unit_s, statfun, jitter, 999, 'right');

% Joint null over lags, for a familywise lag-by-lag statement.
[sta, lag_s] = event_triggered_average(lfp, unit_s, fs, .2, .2);
rng(7)
B = 499; null = zeros(B, numel(lag_s));
for b = 1:B
    null(b,:) = event_triggered_average(lfp, jitter(unit_s), fs, .2, .2).';
end
lagwise = surrogate_maxstat_test(sta.', null, 'two-sided');
```

Jitter on a window shorter than the effect preserves slow rate modulation
and destroys fine timing; it is the usual null for spike-field and
spike-spike locking ([06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md),
[07_COUPLING.md](07_COUPLING.md)). A circular shift of the LFP relative to
the spikes preserves both autocorrelations instead. Neither removes common
stimulus drive: shuffle trials when the question is about trial-specific
coupling.

## References

- Theiler et al. (1992), doi:10.1016/0167-2789(92)90102-S
- Prichard & Theiler (1994), doi:10.1103/PhysRevLett.73.951
- Schreiber & Schmitz (1996), doi:10.1103/PhysRevLett.77.635
- Kugiumtzis (1999), doi:10.1103/PhysRevE.60.2808
- Amarasingham et al. (2012), doi:10.1152/jn.00633.2011
- Platkiewicz et al. (2017), doi:10.1162/NECO_a_00927
- Shorten et al. (2020), doi:10.1371/journal.pcbi.1008054
- Stella et al. (2022), doi:10.1523/ENEURO.0505-21.2022

## Tests

```matlab
run('matlab/tests/smoke_arsenal.m')            % phase randomisation, window jitter
run('matlab/tests/check_arsenal_identities.m') % circular shift, phase, jitter identities
```

No test script yet calls `aaft_surrogate`, `iaaft_surrogate`,
`multivariate_phase_surrogate`, `block_shuffle_surrogate`,
`interval_jitter_surrogate`, `spike_dither_surrogate`,
`trial_shuffle_surrogate`, `local_permutation_surrogate`, `surrogate_test`
or `surrogate_maxstat_test`; the examples above are their only exercise.

## Next steps

Implement and validate pattern jitter, constrained nonstationary surrogates,
trial shifting, cycle surrogates, and conditional TE permutations with
explicit null models. Benchmark Type-I error and power on synthetic data.

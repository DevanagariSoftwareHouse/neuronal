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

## Primer: what would the statistic look like under a specified null?

A surrogate is an alternative dataset constructed to retain some features
and randomize others. The scientific statement comes from those choices.
“The value exceeds shuffled values” is incomplete until the reader knows
what was shuffled, within which groups, and under which invariance assumption.

Let $T_{\mathrm{obs}}$ be the observed statistic and $T_b^*$ the statistic
from surrogate $b$. A right-tail Monte Carlo comparison uses

$$
p=\frac{1+\sum_{b=1}^{B}\mathbf{1}\{T_b^*\geq T_{\mathrm{obs}}\}}{B+1}.
$$

The smallest attainable value is $1/(B+1)$. Increasing $B$ improves Monte
Carlo resolution; it does not repair an inappropriate null. The plus-one
formula has its intended testing interpretation when the observed and
generated statistics satisfy the required exchangeability under that null.

### Toy experiment: conditional timing with fixed interval counts

```matlab
run('matlab/neuronal_startup.m')
rng(61)
origin_s = 0;
width_s = .1;
spike_s = [.011; .012; .034; .121; .145; .241];
jittered_s = interval_jitter_surrogate(spike_s, width_s, origin_s);
edges = 0:.1:.3;
before = spike_counts_edges(spike_s, edges);
after = spike_counts_edges(jittered_s, edges);
assert(isequal(before, after))
disp([before after])
```

The counts `[3; 2; 1]` stay fixed. Positions within each 100 ms interval
change. The corresponding simple conditional null treats positions within
each fixed interval as uniform, given its count. It permits arbitrary
count differences between intervals but does not preserve within-interval
refractory structure. Spike-centred displacement uses different windows
for different observed spikes and is not the same conditional null.

### Pick the temporal resolution of the hypothesis

The jitter width defines which timing structure is randomized and which
coarse counts are retained. It should exceed the fine timing scale being
tested while remaining compatible with the coarse structure conditioned
upon. Small windows can preserve much of a slow effect; large windows can
erase rate changes that should belong to the null. There is no universally
valid width independent of the scientific question and recording support.

Do not jitter across trial boundaries, invalid recording gaps or condition
changes without an explicit model for those regions. If a generator has no
support-mask argument, construct admissible intervals yourself or choose
another generator. The existence of a convenient function is not evidence
that it implements the desired conditional model.

### One surrogate realization must support the whole comparison

When searching over lags or channel pairs, compute all features from each
same surrogate dataset. A maximum statistic then represents the family
actually searched. Independently shuffling each feature destroys that joint
structure. Any data-dependent selection step must also be represented in
the null procedure or separated using independent data.

For CON²PHYS, distinguish within-trial fine timing from trial-specific
coupling beyond common task locking. Fixed-window jitter and within-condition
trial shuffling answer different questions. A circular shift preserves the
circular autocorrelation of a series, not necessarily the finite-window
linear autocorrelation used by an analysis with boundaries.

**Exercise.** Repeat the count-preservation example with spike-centred
dithering. Which counts can change? Then simulate independent trains with
shared slow rate modulation and investigate how jitter width affects a
short-lag synchrony test.

**Reading.** Amarasingham et al. (2012),
[doi:10.1152/jn.00633.2011](https://doi.org/10.1152/jn.00633.2011), explains
the conditional-model interpretation that gives jitter tests their meaning.

## 1. Generators and what they preserve

| Generator | Null model / preserved features | Limitations |
| --- | --- | --- |
| `circular_shift_surrogate` | Every sample and the circular autocorrelation of one series; breaks alignment to a second series or to events | Deterministic for a given shift; choose shifts beyond the autocorrelation time and away from edges |
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

Fixed-window jitter preserves coarse interval counts while randomizing
timing within those intervals. Choose the width relative to the fine timing
question and the coarse structure that must remain; it is one possible
conditional null for spike-field and spike-spike locking ([06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md),
[07_COUPLING.md](07_COUPLING.md)). A circular shift of the LFP relative to
the spikes preserves each series' circular autocorrelation instead. Neither removes common
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

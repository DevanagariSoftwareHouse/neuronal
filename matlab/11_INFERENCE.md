# Statistical inference methods — initial drafts

All methods in `matlab/path` are preliminary. **No MATLAB execution or
Type-I error calibration has been performed in this commit.** Two random
conventions coexist, and both matter for reproducibility:

- the **bootstrap** functions and `paired_signflip_test` create their own
  `mt19937ar` stream from a `seed` argument whose default is **42**, so two
  calls with default arguments draw identical resamples;
- the **permutation, subsampling, Monte Carlo and selection** functions,
  like every surrogate generator, draw from the global stream: use
  `rng(seed)` before calling them.

The question that comes first is always the **experimental unit**: rows
passed to these functions are treated as independent (or exchangeable)
units. Spike samples, adjacent LFP samples and overlapping event windows are
generally **not** independent observations.

## 1. Bootstrap intervals

- `bootstrap_percentile`: percentile interval of the arithmetic mean of a
  vector (nonfinite values dropped; default 1000 draws).
- `bootstrap_ci`: IID resampling of rows for a scalar statistic, with
  `'percentile'` (default), `'basic'` or `'bca'` intervals (jackknife
  acceleration); default 2000 draws.
- `bootstrap_t_ci`: studentised interval; the caller supplies `sefun`,
  evaluated on every resample.
- `paired_difference_ci`: `bootstrap_ci` of the matched differences `b - a`.
- `block_bootstrap_ci`: circular moving blocks of length `L` (default
  `round(sqrt(n))`) or the stationary bootstrap of Politis & Romano, for
  ordered rows; vector statistics allowed.
- `hierarchical_bootstrap_ci`: resample animals, then trials within each
  selected animal; `groups{animal}` is trials x features and the statistic
  receives a cell array (default: mean of animal means).
- `parametric_bootstrap_ci`: fit, simulate `n` rows, re-estimate,
  percentile CI.
- `simultaneous_confidence_band`: max-|t| band over coordinates (for
  example frequencies) from a **joint** bootstrap matrix B x coordinates.

## 2. Jackknife and subsampling

- `jackknife_estimate`, `jackknife_ci`: leave-one-independent-row estimates,
  jackknife SE, normal CI.
- `delete_group_jackknife`: leave-one-group-out estimates; equal-group SE is
  not generally justified for unequal cluster sizes.
- `subsampling_ci`: root-n subsampling intervals; requires suitable
  subsample sizes and regularity conditions.

## 3. Randomisation tests

- `permutation_test`: independent-group exchangeability.
- `paired_permutation_test`: paired sign flips, requiring symmetry under the null.
- `paired_signflip_test`: two-sided sign flips of the mean paired
  difference, own seeded stream; not cluster-based.
- `maxstat_permutation_test`: familywise max-statistic adjustment with jointly permuted labels.
- `cluster_permutation_test`: one-dimensional contiguous clusters of absolute t values. The cluster-forming threshold is a statistic threshold, **not** a significance level; this draft only supports independent groups and one ordered feature axis.
- `monte_carlo_null_test`: draw entire datasets under a specified null generator.

## 4. Model checking, robustness and validation

- `posterior_predictive_check`: posterior predictive discrepancy distribution; predictive tail areas are not calibrated frequentist p-values.
- `sensitivity_analysis`: results across explicitly supplied configurations.
- `stability_selection`: selection frequencies over subsamples; no guaranteed false-discovery bound.
- `blocked_cross_validation`: contiguous test folds with gap/purge region.
- `group_cross_validation`: group-disjoint folds, e.g. leave-one-animal-out.

The two fold builders are documented with the decoders in
[09_MODELS_DECODING.md](09_MODELS_DECODING.md); surrogate-based tests in
[10_SURROGATES.md](10_SURROGATES.md).

## Examples

```matlab
rng(42);
a = randn(20,10); b = randn(20,10);
j = jackknife_estimate(a,@(z)mean(z,1));
[ci,details] = jackknife_ci(a,@(z)mean(z,1),.95);
p = permutation_test(a(:,1),b(:,1),[],199,'two-sided');
c = cluster_permutation_test(a,b,2,199);
folds = group_cross_validation(repelem((1:5)',10),5);
assert(isempty(intersect(folds{1}.train,folds{1}.test)));

% Animal as the unit: one cell per animal, trials x features inside.
groups = arrayfun(@(k) 8 + randn(30,1) + .5*randn, 1:6, 'UniformOutput', false);
[ci_animal, theta] = hierarchical_bootstrap_ci(groups, [], 2000, .95, 7);

% Ordered bins of one recording: blocks, not IID rows.
[ci_block, m] = block_bootstrap_ci(cumsum(randn(2000,1))/50, [], 50, 2000, .95, 7);
```

## Interpretation and safety

Experimental unit is critical: spike samples and adjacent LFP samples are
generally **not** independent observations. Resample/permutate at animal or
trial level as justified by the design. Permutation tests require
exchangeability (or the appropriate restricted invariance), and Monte Carlo
p-values only have their nominal interpretation when the null generator and
test construction are valid. A significant cluster does not establish the
precise onset or spatial extent of the effect. A bootstrap interval for one
recording describes that recording, not the population of animals. Inspect
model fit and synthetic Type-I error before publishing conclusions.

## Suggested validation

1. Run all MATLAB examples and boundary tests.
2. Under simulated nulls, estimate rejection rates at alpha=.05.
3. Under simulated alternatives, measure power.
4. Check independence/exchangeability at animal, trial and electrode levels.
5. Benchmark performance for large spectral maps and spike arrays.

## Tests

```matlab
run('matlab/tests/smoke_arsenal.m')                    % bootstrap_percentile, paired_signflip_test
run('matlab/tests/test_con2phys_battle_regressions.m') % paired_permutation_test
```

Every other function in this chapter is exercised only by the examples
above; none has a regression script yet.

## References

Efron & Tibshirani, *An Introduction to the Bootstrap* (1993); Good, *Permutation Tests*; Maris & Oostenveld, *J Neurosci Methods* (2007), doi:10.1016/j.jneumeth.2007.03.024; Politis, Romano & Wolf, *Subsampling* (1999); Politis & Romano (1994), the stationary bootstrap; Davison & Hinkley, *Bootstrap Methods and Their Application* (1997); Gelman et al., *Bayesian Data Analysis*.

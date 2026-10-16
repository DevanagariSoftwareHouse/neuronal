# Statistical inference methods — initial drafts

All methods in `matlab/path` are preliminary. **No MATLAB execution or Type-I error calibration has been performed in this commit.** Use `rng(seed)` before stochastic functions.

## Added methods

- `jackknife_estimate`, `jackknife_ci`: leave-one-independent-row estimates, jackknife SE, normal CI.
- `permutation_test`: independent-group exchangeability.
- `paired_permutation_test`: paired sign flips, requiring symmetry under the null.
- `maxstat_permutation_test`: familywise max-statistic adjustment with jointly permuted labels.
- `cluster_permutation_test`: one-dimensional contiguous clusters of absolute t values. The cluster-forming threshold is a statistic threshold, **not** a significance level; this draft only supports independent groups and one ordered feature axis.
- `subsampling_ci`: root-n subsampling intervals; requires suitable subsample sizes and regularity conditions.
- `delete_group_jackknife`: leave-one-group-out estimates; equal-group SE is not generally justified for unequal cluster sizes.
- `monte_carlo_null_test`: draw entire datasets under a specified null generator.
- `parametric_bootstrap_ci`: fit, simulate, re-estimate, percentile CI.
- `posterior_predictive_check`: posterior predictive discrepancy distribution; predictive tail areas are not calibrated frequentist p-values.
- `blocked_cross_validation`: contiguous test folds with gap/purge region.
- `group_cross_validation`: group-disjoint folds, e.g. leave-one-animal-out.
- `sensitivity_analysis`: results across explicitly supplied configurations.
- `stability_selection`: selection frequencies over subsamples; no guaranteed false-discovery bound.

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
```

## Interpretation and safety

Experimental unit is critical: spike samples and adjacent LFP samples are generally **not** independent observations. Resample/permutate at animal or trial level as justified by the design. Permutation tests require exchangeability (or the appropriate restricted invariance), and Monte Carlo p-values only have their nominal interpretation when the null generator and test construction are valid. A significant cluster does not establish the precise onset or spatial extent of the effect. Inspect model fit and synthetic Type-I error before publishing conclusions.

## Suggested validation

1. Run all MATLAB examples and boundary tests.
2. Under simulated nulls, estimate rejection rates at alpha=.05.
3. Under simulated alternatives, measure power.
4. Check independence/exchangeability at animal, trial and electrode levels.
5. Benchmark performance for large spectral maps and spike arrays.

## References

Efron & Tibshirani, *An Introduction to the Bootstrap* (1993); Good, *Permutation Tests*; Maris & Oostenveld, *J Neurosci Methods* (2007), doi:10.1016/j.jneumeth.2007.03.024; Politis, Romano & Wolf, *Subsampling* (1999); Davison & Hinkley, *Bootstrap Methods and Their Application* (1997); Gelman et al., *Bayesian Data Analysis*.

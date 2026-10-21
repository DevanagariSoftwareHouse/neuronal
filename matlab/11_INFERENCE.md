# Statistical inference methods — initial drafts

[Índice](README.md) · [Anterior](10_SURROGATES.md) · [Próximo](12_REVIEW.md)

All methods in `matlab/path` are preliminary. **No MATLAB execution or
Type-I error calibration has been performed in this commit.** Two random
conventions coexist, and both matter for reproducibility:

- the **bootstrap** functions and `paired_signflip_test` create their own
  `mt19937ar` stream from a `seed` argument whose default is **42**, so two
  calls with default arguments draw identical resamples;
- the **permutation, subsampling, Monte Carlo and selection** functions,
  like every surrogate generator, draw from the global stream: use
  `rng(seed)` before calling them.

The question that comes first is always the **experimental unit**.
IID procedures treat rows as independent; permutation procedures require
the specified exchangeability; block and hierarchical methods preserve
particular dependence structures instead. Spike samples, adjacent LFP samples and overlapping event windows are
generally **not** independent observations.

## Primer: estimand, resampling axis, dependence, interval construction

These are four separate decisions. First define the population quantity.
Then identify what could be sampled again in the experiment. Preserve the
dependence and pairing relevant to that sampling process. Only then choose
how the resampled estimates become an interval.

| Resampling axis | Meaning of one draw | Required structure | Scope of inference |
| --- | --- | --- | --- |
| Animal | A complete animal contribution | Retain its conditions and selected summaries together | Population of animals under the sampling assumptions |
| Trial | A trial contribution within a defined condition/session | Preserve matching; handle serial dependence | Trials under that design, conditional on recorded subjects |
| Cluster/unit | One sampled cluster contribution | Justify exchangeability and within-animal dependence | A defined cluster population, not automatically animals |
| Time block | Consecutive rows from one process | Preserve synchronous columns and local temporal dependence | The recording/process under stationarity assumptions |
| Hierarchy | Animal, then subordinate observations | Resample within the appropriate selected parent | A specified multilevel sampling model |

A channel axis is not automatically a replication axis: neighbouring
electrodes measure overlapping sources. A paired axis is an identity
constraint on resampling. Two brain areas recorded in the same animal
should travel together when the target is a within-animal contrast.

### Empirical distribution and bootstrap estimates

For independent observations $x_1,\ldots,x_n$, the empirical distribution
places mass $1/n$ at each observation:

$$
\widehat F_n=\frac1n\sum_{i=1}^{n}\delta_{x_i},\qquad
\widehat\theta^*=T(x_1^*,\ldots,x_n^*),\quad x_i^*\sim\widehat F_n.
$$

$\delta_{x_i}$ denotes a point mass, and $T$ is the chosen statistic. This
is a sampling distribution used to generate resamples, not a likelihood
function. The bootstrap distribution approximates repeated-estimation
variation under its assumptions; it is not additional observed biology.

### Toy experiment: preserve matched animals

```matlab
run('matlab/neuronal_startup.m')
rng(71)
animal_baseline = 10 + 3*randn(18,1);
area_a = animal_baseline + .5*randn(18,1);
area_b = animal_baseline + 1 + .5*randn(18,1);
paired = [area_a area_b]; % each row is one animal, both areas
contrast = @(z) mean(z(:,2)-z(:,1));
[ci, estimate, draws] = bootstrap_ci( ...
    paired, contrast, 2000, .95, 'percentile', 17);
disp([estimate ci])
```

The population contrast in this simulation is 1 Hz. Drawing a row selects
both measurements of that animal. Independently resampling the columns
would discard their covariance. The statistic could equivalently operate
on the vector of paired differences. Neither formulation implies that
clusters in different brain areas are individually matched neurons.

### Compare interval constructions while holding the question fixed

```matlab
methods = {'percentile', 'basic', 'bca'};
intervals = zeros(numel(methods),2);
for k = 1:numel(methods)
    intervals(k,:) = bootstrap_ci( ...
        paired, contrast, 2000, .95, methods{k}, 17);
end
disp(table(methods(:), intervals(:,1), intervals(:,2), ...
    'VariableNames', {'Method','Lower','Upper'}))
```

In this implementation, using the same data, statistic, draw count and seed
gives the same IID draws across these three interval constructions. This
isolates the interval rule. It does not establish equivalence of random
draws across different algorithms.

| Construction | How the interval is formed | Main diagnostic |
| --- | --- | --- |
| Percentile | Quantiles of bootstrap estimates | Bias and skewness of the statistic |
| Basic | Reflect bootstrap quantiles around the observed estimate | Parameter boundaries and transformation sensitivity |
| BCa | Adjust quantile levels using bias correction and jackknife acceleration | Stability of leave-one-unit estimates |
| Studentized | Quantiles of bootstrap standardized errors | Valid, nondegenerate SE estimates on every resample |

Bayesian bootstrap changes the resampling distribution to random weights;
it is not just another endpoint rule for the same IID draws. Report such
comparisons separately and verify implementation availability on the branch
used. Hierarchical and block bootstrap similarly change the sampling scheme.
No interval construction repairs an incorrect resampling unit.

When reporting multiple methods, predefine the collection and show all
results, including failures and nonfinite intervals. Do not choose the
method whose interval excludes zero. To compare coverage, repeatedly
simulate complete datasets with known truth; the fraction of intervals
containing that truth estimates coverage. Also report interval-length
distribution and Monte Carlo uncertainty. One dataset cannot reveal a
method's true coverage rate.

### Ordered observations: a stationary toy process

```matlab
rng(72)
rho = .8;
x = zeros(2000,1);
x(1) = randn/sqrt(1-rho^2); % stationary marginal for unit innovation variance
for t = 2:numel(x)
    x(t) = rho*x(t-1) + randn;
end
[ci_time, mean_time] = block_bootstrap_ci( ...
    x, [], 25, 2000, .95, 17, true); % stationary=true explicitly
```

Here the stationary bootstrap continues the current index with probability
$1-1/L$ and starts at a new random index with probability $1/L$; expected
block length is $L$. Circular wrap-around is part of the scheme. Inspect
stationarity and repeat plausible block lengths. A random walk is not a
stationary replacement for this example.

**Implementation caveat.** The current `stationary=false` branch reshapes
a starts-by-offsets matrix in MATLAB column-major order, interleaving block
starts rather than concatenating complete blocks. Do not rely on it for
order-sensitive statistics until corrected and checked. The example above
uses the separate stationary path. This documentation change does not fix
the underlying implementation.

**Exercise.** Increase `rho` while keeping the recording length fixed.
Compare IID and stationary-bootstrap intervals for the mean. Then add more
animals rather than more time samples: explain why that changes the scope
of the scientific inference.

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
rho = .8; x = zeros(2000,1); x(1) = randn/sqrt(1-rho^2);
for t = 2:numel(x), x(t) = rho*x(t-1) + randn; end
[ci_block, m] = block_bootstrap_ci(x, [], 50, 2000, .95, 7, true);
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

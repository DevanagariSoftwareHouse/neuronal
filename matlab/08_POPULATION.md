# Population geometry, assemblies and dynamics (MATLAB)

The primitives in `path/` take a population as a matrix of **observations x
units**: time bins x units for continuous activity, trials x units for
trial responses, or a latent trajectory of time x dimensions. They separate
**variance structure and dimensionality**, **coactivation assemblies**,
**condition and noise structure**, **targeted and communication
subspaces**, and **dynamics and factorisation**. The observation choice
determines what any geometry means, and none of these files reproduces the
complete published pipeline it borrows from: `population_pca` is not GPFA,
LFADS, jPCA or dPCA; `tensor_cp_als` is not TCA; `gaussian_process_smoothing`
is not GPFA. Fit every projection, rank and penalty on **training** data
only ([09_MODELS_DECODING.md](09_MODELS_DECODING.md)).

## 1. Variance structure and dimensionality

```matlab
counts = spike_bins(units_s, 0:.05:duration_s);         % bins x units
pca = population_pca(counts, 10);                        % mean, loadings, scores
pr = participation_ratio(counts);
scale = population_dimension_scaling(counts, [5 10 20], 25, 42);
fit = eigenspectrum_powerlaw(pca.eigenvalues(1:50));
```

`population_pca` centres columns and returns `mean`, `loadings`, `scores`,
`eigenvalues` (all of them, divided by `n-1`) and `explained`.
`participation_ratio` is `tr(C)^2/tr(C^2)` of the centred covariance; raw
variance differences between units drive it, so z-score first if that is
the intended geometry. `population_dimension_scaling` draws random unit
subsets of each size from its own `mt19937ar` stream (default seed 42) and
returns `dimension_samples` and `mean_dimension`.
`eigenspectrum_powerlaw` fits `log v` against `log rank` over descending,
positive eigenvalues and returns `exponent`, `intercept`, `ranks` and
`r_squared`; eigenvalue estimates of finite samples are biased, so compare
against shuffled or cross-validated spectra.

## 2. Assemblies

```matlab
model = assembly_pca(counts, 5);
z = (counts - model.mean) ./ model.std;
strength = assembly_expression(z, model.templates(:, model.eigenvalues(1:5) > model.mp_upper));
```

`assembly_pca` z-scores nonnegative counts (silent units must be removed),
returns `templates`, `scores`, `eigenvalues`, `mean`, `std` and the
Marchenko-Pastur upper edge `mp_upper`, an **iid** null approximation and
not a surrogate test. `assembly_expression` returns
`(z*w)^2 - (z.^2)*(w.^2)`, the projection with diagonal (single-unit) terms
removed; `z` must use the fitted unit order and normalisation. ICA and
formal assembly significance are not implemented.

## 3. Condition means and noise structure

```matlab
x = trial_features(units_s, windows);                    % trials x units
[rho, residual] = noise_correlation(x, condition);
parts = condition_marginalization(x, condition);
Q = greedy_modularity(max(rho - diag(diag(rho)), 0));
```

`noise_correlation` subtracts each condition's mean response and returns the
correlation matrix of the residuals. `condition_marginalization` returns
`conditions`, `group_index`, `condition_means`, `counts`, `noise_residual`
and `grand_mean`; it is a primitive of demixing, not dPCA.
`greedy_modularity` returns the best modularity reached by greedy merging of
a symmetric nonnegative weight matrix, a heuristic local optimum without
community labels. Correlations of rates depend on bin size, rate and
nonstationarity.

## 4. Targeted and communication subspaces

```matlab
dDR = targeted_dimensionality_reduction(x(train,:), condition(train));
lda = linear_discriminability(x(train & condition==1,:), x(train & condition==2,:));
rrr = reduced_rank_regression(source(train,:), target(train,:), 3, 1e-3);
p = communication_subspace_projection(source(test,:), rrr);
```

`targeted_dimensionality_reduction` builds the two-condition dDR plane: the
normalised mean difference and the leading residual direction orthogonal to
it (`basis`, `center`, `scores`, `conditions`). `linear_discriminability`
returns pooled-covariance `dprime_squared`, the `discrimination_axis`,
`mean_difference` and the ridge (default 1e-6), with groups of unequal
size handled separately. `reduced_rank_regression` fits ridge regression,
projects onto the leading `rank` directions of the prediction and returns
`coefficients`, `source_axes`, `target_axes`, means and `prediction`; with
ridge above zero, "ridge then projection" is a heuristic, not the exact
rank-constrained minimum. `communication_subspace_projection` centres new
source activity with the training mean and projects onto `source_axes`.

## 5. Dynamics, factorisation and smoothing

```matlab
dyn = jpca_dynamics(latent_time_by_dim, .01);           % k between 2 and 10
rng(3)
cp = tensor_cp_als(neuron_by_time_by_trial, 4, 40, 1e-7);
gp = gaussian_process_smoothing(rates(1:500,:), t_s(1:500), .1, 1, .1);
```

`jpca_dynamics` fits a skew-symmetric generator to central-difference
derivatives of a pre-smoothed, aligned trajectory and returns `generator`,
`eigenvalues`, `residual_fraction` and `predicted_derivative`; it is not the
full jPCA pipeline. `tensor_cp_als` runs ridge CP-ALS from random factors of
the global stream (seed outside), with no normalisation, restarts or rank
selection, and returns neuron, temporal and trial factors and
`relative_error`. `gaussian_process_smoothing` applies a squared-exponential
kernel smoother to each column with fixed hyperparameters, by Cholesky, for
at most 2000 strictly increasing time points.

## Tests

From the repository root:

```matlab
run('matlab/tests/smoke_population.m')         % geometry, dDR, RRR, jPCA, CP, GP
run('matlab/tests/smoke_arsenal.m')            % PCA, participation ratio, assemblies, noise correlation
run('matlab/tests/smoke_imported_helpers.m')   % greedy_modularity
run('matlab/tests/check_arsenal_identities.m') % PR, assembly, discriminability, RRR, jPCA identities
```

Synthetic recoveries are weak; see [12_REVIEW.md](12_REVIEW.md) for the
open CP/ALS and dDR items.

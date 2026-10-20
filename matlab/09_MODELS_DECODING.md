# Point-process models, decoding and validation folds (MATLAB)

The primitives in `path/` separate **design matrices**, **Poisson
regression of binned counts**, **coupled multi-unit models**, **held-out
decoding**, and **fold construction**. They are fitted on explicit inputs:
counts are **time bins x units**, trial features **trials x units**, labels
a column vector. Coefficients describe conditional predictive dependence
under the model, not synapses or causation, and a decoding score is only as
honest as the folds that produced it.

## 1. Spike-history design and Poisson GLM

```matlab
bin_s = .005;
counts = spike_bins(units_s, 0:bin_s:duration_s);          % bins x units
[X, valid] = spike_history_design(counts, 10);              % 10 lags
glm = poisson_spike_glm(X, counts(valid, 1), bin_s, 1e-4);
```

`spike_history_design` places unit `j` at lag `l >= 1` in column
`(j-1)*lags + l`; contemporaneous counts are never used, and only bins
`lags+1..n` are returned (`valid_bins`). It is capped at 1e7 design values.
`poisson_spike_glm` fits a log-link Poisson model with an offset of
`log(bin_seconds)` and an unpenalised intercept by penalised Newton/IRLS;
it returns `intercept`, `coefficients`, `expected_count`, `iterations`
and a `note`. The linear predictor is clipped to `[-20, 20]`, which changes
the objective whenever it is active. Shared latent drive, refractoriness
and overdispersion are not modelled.

## 2. Coupled multi-unit filters

```matlab
cf = coupling_filters(counts, 10, bin_s, 1);
imagesc(squeeze(cf.filters(1,:,:)));                        % target 1: source x lag
```

`coupling_filters` fits one Poisson GLM per target on the history of every
unit (including itself) and returns `filters` as **target x source x lag**,
`intercept`, `log_rate`, `valid_bins`, `lag_seconds`, `ridge` and a `note`.
The coefficients are conditional log-rate effects given the observed units;
they are **not** synaptic connections and not evidence of physical
causality. Validate residuals and held-out likelihood.

## 3. Held-out decoding

```matlab
r = crossvalidated_ridge_decoder(x, labels, 5, 1);          % two classes
[score, detail] = decode_trials(x, labels, 7);               % multiclass
info_bits = decoded_mi(detail.observed, detail.predicted);
```

`crossvalidated_ridge_decoder` is a binary ridge least-squares classifier
with **interleaved** folds (`mod(row, folds)`), fold-specific z-scoring and
an unpenalised intercept; it returns `prediction`, `scores`, `accuracy` and
`classes`. Interleaved folds leak temporal structure for ordered rows:
use contiguous folds for time series. `decode_trials` uses five contiguous
folds, one-vs-rest ridge and balanced accuracy, skips folds whose training
rows lack two examples of each class, and reports uncalibrated softmax
`probability`; `seed` is metadata only. `decoded_mi` is the plug-in
information between labels and predictions, without bias correction.
Never fit PCA, dDR or any projection on the full dataset before held-out
decoding ([08_POPULATION.md](08_POPULATION.md)).

## 4. Folds that respect dependence

```matlab
folds = blocked_cross_validation(n_bins, 5, 20);            % gap of 20 rows
rng(11)
gfolds = group_cross_validation(animal_id, 6);               % leave-animals-out
for k = 1:numel(gfolds)
    train = gfolds{k}.train; test = gfolds{k}.test;
end
```

`blocked_cross_validation` returns contiguous test blocks and removes `gap`
rows on either side of each test block from training, so autocorrelated
neighbours do not leak. `group_cross_validation` assigns whole groups
(animals, sessions) to folds using the global random stream and returns
`train`, `test` and `test_groups`; no group occurs in both sets of a fold.
Fitting is the caller's responsibility; these functions only index.

## Tests

From the repository root:

```matlab
run('matlab/tests/smoke_arsenal.m')            % Poisson GLM
run('matlab/tests/smoke_bosc_circ_glm.m')      % history design, coupling filters
run('matlab/tests/smoke_population.m')         % ridge decoder
run('matlab/tests/smoke_imported_helpers.m')   % decode_trials, decoded_mi
```

No script exercises `blocked_cross_validation` or `group_cross_validation`
yet beyond the example in [11_INFERENCE.md](11_INFERENCE.md). Synthetic fits
check shapes and recovery on simulated data; they are not likelihood or
calibration validations.

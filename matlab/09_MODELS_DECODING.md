# Point-process models, decoding and validation folds (MATLAB)

[Índice](README.md) · [Anterior](08_POPULATION.md) · [Próximo](10_SURROGATES.md)

The primitives in `path/` separate **design matrices**, **Poisson
regression of binned counts**, **coupled multi-unit models**, **held-out
decoding**, and **fold construction**. They are fitted on explicit inputs:
counts are **time bins x units**, trial features **trials x units**, labels
a column vector. Coefficients describe conditional predictive dependence
under the model, not synapses or causation, and a decoding score is only as
honest as the folds that produced it.

## Primer: what can be predicted on observations not used for fitting?

An encoding model predicts activity from covariates. A decoder predicts
a condition or behavioural variable from activity. Neither establishes
that the brain uses the fitted computation. Their evidence comes from
held-out performance against a relevant baseline.

For bin count $y_t$, covariate vector $x_t$, and exposure $\Delta t$,
a log-link Poisson model uses

$$
y_t\sim\operatorname{Poisson}(\mu_t),\qquad
\mu_t=\Delta t\exp(\beta_0+x_t^\mathsf{T}\beta).
$$

The exponential predicts a rate; multiplying by exposure predicts a count.
The `log(bin_seconds)` offset encodes this distinction. A coefficient is a
conditional log-rate change per unit change in its covariate, given the
other included covariates and this model specification.

### Toy experiment: leakage from repeated observations

This indexing example needs only base MATLAB. It shows why repeated bins
from one trial cannot be split as if they were separate experiments.

```matlab
trial_id = repelem((1:12)', 10); % 10 observations from each trial
n = numel(trial_id);
interleaved_test = mod((1:n)', 5) == 0;
shared_trials = intersect(unique(trial_id(interleaved_test)), ...
    unique(trial_id(~interleaved_test)));
assert(numel(shared_trials) == 12)

group_test = ismember(trial_id, [3 6 9 12]);
assert(isempty(intersect(unique(trial_id(group_test)), ...
    unique(trial_id(~group_test)))))
```

Interleaving has placed every trial on both sides of the split. A model
can exploit trial-specific structure that will not generalize to a new
trial. Group separation removes that particular overlap. It does not
guarantee independence across adjacent trials, nor generalization to a new
animal. Choose the split according to the intended deployment population.

### Evaluate the whole fitted pipeline

Training includes standardization, missing-value handling, feature
selection, PCA, rank choice and regularization selection. Fit these steps
inside the training partition. Hyperparameter selection needs an inner
validation split; the outer test partition estimates generalization.
Temporal filtering and smoothing also require care across split boundaries.

For binary decoding, report the confusion matrix, class-specific recall,
balanced accuracy, ordinary accuracy, and prediction coverage. Balanced
accuracy is the mean of the two recalls; a majority-class predictor has
balanced accuracy 0.5 when both classes are evaluated, even if ordinary
accuracy is high. A skipped prediction should be reported, not silently
removed from the description of performance.

For CON²PHYS, distinguish predicting later trials of a recorded animal
from predicting trials of an unseen animal. The latter requires animal-level
separation and a feature definition that transfers across animals. For a
Poisson model, inspect held-out likelihood and residuals in addition to
coefficient plots; apparent convergence does not establish an adequate
generative model.

**Exercise.** Give each trial a random label and a unique, repeated feature
vector. Compare a nearest-neighbour decoder with interleaved versus
trial-disjoint splits. Explain how excellent interleaved performance can
coexist with no generalizable relation between features and labels.

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
the objective whenever it is active. Shared latent drive and overdispersion are not handled automatically.
History covariates can represent refractory dependence, but the primitive
does not impose or validate a physiological refractory model.

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

# Questionnaire resampling

Run scripts as `con2phys.q01_firing_rate`, etc. They retain the workspace,
consume **one raw recording** in `data`, and return `q01` ... `q15`.
They do not load or pool recordings automatically. `data` contains `srate`,
`lfp_1/2/3` (channels x samples), `spike_timestamp` (seconds), `spike_cluster`,
`waveform` (clusters x waveform samples), `waveform_cluster`, `waveform_area`.

```matlab
run('analysis/a00_startup.m')
% Load one raw recording into data before running a question.
qcfg = struct();
qcfg.bootstrap = 2000;
qcfg.seed = 42;
qcfg.inference = struct('method','auto','level',.95);
con2phys.q01_firing_rate
q01.summary
q01.inference{1}
```

`auto` uses percentile resampling of cluster summaries for Q01/Q07/Q08/Q09/Q10,
and stationary bootstrap for ordered time-block/trial rows elsewhere.
It is a configurable starting point, not an empirically validated choice of
block length. Cluster CIs describe within-recording cluster sampling, not
animal replication. Q08 and Q10 condition on per-cluster estimates/eligibility.

## Selecting a method

```matlab
qcfg.inference.method = 'bca'; % cluster summaries
con2phys.q01_firing_rate
qcfg.questions.q02 = struct('method','stationary','block_length',4);
con2phys.q02_broadband_power
% Q02 rows are block_seconds summaries: 4 rows is 4*block_seconds seconds.
qcfg.questions.q15 = struct('method','balanced','allow_iid',true);
% Set allow_iid only after justifying independence of the retained trials.
con2phys.q15_signal_complexity
```

Methods: `percentile`, `basic`, `bca`, `balanced`, `bayesian`, `studentized`,
`block`, `stationary`, `hierarchical`, `parametric`, `wild`, `subsampling`,
`jackknife`. All call their corresponding primitives in `matlab/path`.
`auto` is resolved before reporting. No failed method falls back silently.

- `bayesian` returns **credible** intervals; non-mean statistics require
  `weighted_statfun(x,w)` estimating exactly the same quantity.
- `studentized` uses `std(x)/sqrt(n)` for a scalar mean; other estimands require
  `sefun(x)`. Zero replicate SE is an error, not silently discarded.
- `wild` uses intercept-only OLS for scalar means; it is not a VAR or
  cluster-wild bootstrap. Other statistics are rejected.
- `parametric` requires `fitfun(x)` and `simulatefun(parameters,n)`. The latter
  must generate the same observation representation consumed by the statistic.
- `hierarchical` requires explicit `groups` and `group_statfun(groups)`.
  Their point estimate must match the question estimate. Animal identities
  and nesting are never invented; this is an advanced adapter, not automatic
  across-animal analysis. Do not represent crossed trials/units as nested.
- `subsampling` accepts `subsample_size`; it assumes root-n scaling.
- `jackknife` stores the original estimate and the full jackknife result;
  its interval is centered on the bias-corrected estimate.

Supply group-specific callbacks using `group_options`, a cell with one option
struct for each of the three groups. Global inference options are overridden
by `qcfg.questions.qNN`, then by the relevant group option.
For example, custom Bayesian statistics for Q11/Q12 must process the observed
label column and the relevant prediction column, with observation weights.
For Q13 the input rows are trial IDs, so a callback must operate on the trial
data referenced by those IDs, not average the numerical IDs.

IID methods on trial/time-block rows require explicit `allow_iid=true`.
Block length is in **input rows**, not samples or seconds. All synchronous
features stay together. Ordered means retain missing rows in a common index grid. Each replicate
resamples row IDs and averages only finite values. `qcfg.minimum_finite_rows`
(default 3) applies to the observation and every replicate. If any replicate
fails this minimum, its interval is unavailable; replicates are not silently
dropped or retried. This does not correct informative missingness.
At least three usable observations are required; otherwise intervals remain
NaN with a status. Invalid/sparse replicate statistics raise an error.

## Trial schema

Q10-Q13 and Q15 require explicit mapping of `data.trial` columns:

```matlab
% EXAMPLE schema only: replace indices using your dataset documentation.
qcfg.trial_columns = struct('trial_start',1,'stim_start',2, ...
    'outcome',3,'trial_end',4,'A',5,'C',6);
```

Times must be seconds and strictly ordered within a trial, within recording
bounds. Labels A/C may be missing; the questions check their own label needs.
Alternatively set `data.trial_columns` to the same mapping structure.

## Estimators and outputs

`summary` contains `group`, `mean`, `ci_low`, `ci_high` (and `n` for marginal
summaries). Endpoint names no longer hard-code 95% because `level` is configurable.
`inference{k}` stores the method, level, confidence/credible kind, axis, n,
point estimate, endpoints, draws, scope and status. Studentized draws are
pivots, explicitly identified by `draws_kind`, rather than raw estimates.

- Q09 resamples narrow proportions and transforms endpoints to broad/narrow
  ratios. Its inference objects remain on the proportion scale. Boundary
  samples (no narrow or no broad clusters) have unavailable ratio intervals.
- Q11/Q12 retain circular-shift null outputs, controlled independently by
  `qcfg.null_replicates` (100 by default, 0 to disable). Their CIs condition on
  the fitted held-out predictions. They do **not** include training uncertainty.
  All groups share trial rows and resampling seed; full held-out coverage is
  required. A Q12 replicate missing any of the three classes is undefined and
  raises an error rather than changing the target by dropping a class.
- Q13 fixes a matched cluster subset per area and recomputes participation
  ratio from whole resampled trials. The point and replicate estimators match.
  Subset sensitivity is separate; changing the seed changes the chosen subset.
- Q02-Q06/Q14 resample block-level statistics, not reconstructed raw signals.
  Their target remains the mean blockwise statistic. Q15 resamples trial entropy.

Supported empirical methods also report all three paired contrasts and a
within-recording decision. They never select winners by marginal CI overlap.
Population claims still require animal-level analysis.

Run `test_questionnaire_resampling` after adding `matlab/tests` to the path.
It checks method dispatch, reproducibility/RNG restoration, dependency guards,
fixed-block contiguity, shared resampling, and all fifteen scripts on synthetic
data. This is a functional regression test, not a coverage study.

## Re-answer and export the questionnaire

`questionarie.tex` contains all 15 original prompts, analytical approaches and
limitations. Its initial edition explicitly marks numerical results unavailable.
To execute the question scripts and regenerate a populated report:

```matlab
run('analysis/a00_startup.m')
% data must contain one actual raw recording; configure trial_columns first.
qcfg.inference = struct('method','auto','level',.95);
qcfg.bootstrap = 2000;
results = con2phys.run_questionnaire(data,qcfg);
% Default: analysis/results/questionnaire/questionarie.tex and questionarie.mat
```

Every question runs independently; failures are logged in the MAT evidence
bundle and displayed in the TeX report. Successful outputs retain the exact
method, coverage, interval kind, observation count, block length, configuration
and recording duration. Bayesian credible intervals are never labelled CIs.
The runner isolates each script in a fresh function workspace. It does not
aggregate recordings or select winners from interval overlap,
or fill personal Section 2 ratings. Set `qcfg.report_revision` to the commit SHA
for manual runs; CI obtains it from GITHUB_SHA.

Compile from the directory containing the generated TeX:

```sh
pdflatex -interaction=nonstopmode -halt-on-error questionarie.tex
```

You can re-export saved evidence without rerunning analyses:

```matlab
load('analysis/results/questionnaire/questionarie.mat','results')
write_questionnaire_tex(results,'questionarie.tex')
```

## Contrast decisions and review scope

`questionnaire_decide` uses all three pairwise comparisons as the family, before
selecting a candidate minimum (Q01/Q10/Q14) or maximum (other questions). It
reports centered-bootstrap two-sided p-values, Holm adjustment, and Bonferroni
basic simultaneous intervals at family alpha=0.05. A candidate must beat both
competitors under both gates. These are approximate bootstrap tests; the
simultaneous intervals are Bonferroni intervals, not "Holm-adjusted CIs".
The decision alpha is 0.05 regardless of the marginal interval level.

Ordered mean summaries use a common row-index matrix and matching resampling
plans, preserving cross-area dependence and NaN locations. Q11-Q13 already
use joint observations. Compatible raw statistic draws are required; Bayesian,
studentized-pivot, model-callback and jackknife results are not subtracted as
though they were interchangeable empirical replicates. Unit summaries use
different streams, but decisions require explicit `qcfg.independent_groups=true`
with scientific justification. Separate recorded areas alone do not establish
independent biological replicates. Q03 candidate screens and Q09 waveform
proxies do not automatically select physiological ripple/E-I winners.

The report displays the choice boxes, contrast table, and within-recording
scope. No 18-animal population decision has been implemented. The per-question
methodological alternatives in the review (FA dimensionality, alternative
timescale fit, ripple validation, and so on) remain separate changes.

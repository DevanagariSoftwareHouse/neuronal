# Conventions shared by every function in `path/` (MATLAB)

[Índice](README.md) · [Próximo](01_STORAGE.md)

This chapter is read first. It fixes the units, time origin, bin rules,
array layouts, randomness and scope that the later chapters assume, so they
do not repeat them. Each function's help text remains the authority for its
exact inputs, defaults and outputs (`help name`, `help Contents`).

## Primer: start with a question and an observation unit

Before choosing a function, write a sentence containing the measured
quantity, the comparison, and the population to which it should apply.
For example: “Estimate the mean within-animal difference in trial firing
rate between conditions B and A.” This specifies an **estimand**: the
population quantity the analysis attempts to estimate. A rate, a rate
difference, and a probability of correct decoding are different estimands.

A recording has several axes that play different roles:

| Axis | What one entry represents | What it does not automatically provide |
| --- | --- | --- |
| Sample | One voltage measurement on a clock | An independent replicate |
| Event | One timestamp used as an anchor | An independent trial |
| Cluster | A label assigned to detected spikes | A verified single neuron |
| Channel | An electrode measurement | An independent neural source |
| Trial | One experimental episode | Independence from adjacent trials |
| Animal | One biological subject | Many subjects when many channels are recorded |

Keep these identifiers beside derived features. Averaging over an axis
removes information: after pooling all spikes across animals, their
between-animal variability cannot be reconstructed from the pooled rate.
Likewise, pairing requires identities, not merely two equally long vectors.

### A small example of weighting

Suppose one animal contributes two trial rates, `[2 4]` Hz, and another
contributes four, `[8 10 12 14]` Hz. The mean over all trials weights animals
by their trial counts; the mean of animal means weights animals equally.
Neither is an arithmetic error, but they answer different questions.

```matlab
animal_rates = {[2; 4], [8; 10; 12; 14]};
pooled_trial_mean = mean(vertcat(animal_rates{:})); % 50/6 Hz
equal_animal_mean = mean(cellfun(@mean, animal_rates)); % 7 Hz
```

For animal means $m_a$ and trial counts $n_a$, these estimators are

$$
\widehat\mu_{\mathrm{pooled}}=\frac{\sum_a n_a m_a}{\sum_a n_a},
\qquad
\widehat\mu_{\mathrm{animal}}=\frac{1}{A}\sum_{a=1}^{A}m_a.
$$

Here $A$ is the number of animals. Unequal observation time introduces a
second distinction: total counts divided by total exposure is an
exposure-weighted rate, not the unweighted mean of interval rates.

### Clock arithmetic before signal analysis

```matlab
fs = 500;
sample_idx = (1:5)';
sample_time_s = (sample_idx - 1)/fs;
event_s = .0031;
containing_idx = floor(event_s*fs) + 1; % 2
nearest_idx = round(event_s*fs) + 1;    % 3
```

The clock step is 2 ms; the event itself need not lie on that grid. Preserve
its original timestamp when sub-sample timing matters. For a block starting
at global sample `first`, its origin is `(first-1)/fs`, and event times
passed to functions assuming time zero must have that origin subtracted.

**Exercise.** Duplicate every trial of the first animal. Which mean changes?
Should duplicating stored observations create new biological evidence?
Use this distinction when choosing the resampling axis in
[11_INFERENCE.md](11_INFERENCE.md). Inference is planned here, even when its
numerical implementation appears near the end of the reading order.

## Reading order

| # | Chapter | Covers |
| --- | --- | --- |
| 00 | [Conventions](00_CONVENTIONS.md) | units, time, bins, layouts, randomness |
| 01 | [Storage](01_STORAGE.md) | binary files, catalog, memory maps |
| 02 | [Preprocessing](02_PREPROCESSING.md) | references, bandpass, CSD, lead fields |
| 03 | [Spikes](03_SPIKES.md) | detection, waveforms, unit quality |
| 04 | [Spike trains](04_SPIKE_TRAINS.md) | counts, rates, ISI, correlograms, distances |
| 05 | [Spectra and oscillations](05_SPECTRA_OSCILLATIONS.md) | PSD, aperiodic, wavelets, cycles, BOSC, ripples |
| 06 | [Event alignment](06_EVENT_ALIGNMENT.md) | event sources, aligned segments, triggered averages, PETH |
| 07 | [Coupling](07_COUPLING.md) | coherence, phase synchrony, circular stats, PAC, information |
| 08 | [Population](08_POPULATION.md) | dimensionality, assemblies, subspaces, dynamics |
| 09 | [Models and decoding](09_MODELS_DECODING.md) | Poisson GLMs, decoders, folds |
| 10 | [Surrogates](10_SURROGATES.md) | null generators, Monte Carlo tails |
| 11 | [Inference](11_INFERENCE.md) | bootstrap, jackknife, permutation, validation |
| 12 | [Review](12_REVIEW.md) | corrections, open items, execution status |

The order follows the data: stored arrays are read (01), cleaned (02),
reduced to spikes (03-04) or band-limited signals (05), aligned to events
(06), related to each other (07-08), modelled (09), and evaluated with null models and uncertainty (10-11).
The estimand, experimental unit and validation design are chosen before
these operations; their detailed computational treatment appears later.

## 1. Units

Time is **seconds**, sampling rate **Hz**, frequency **Hz**, phase
**radians**, lengths in **metres** where a physical geometry is required
(`spacing_m`, `depth_m`). Voltages keep the units of the input; functions
never rescale them silently. Information is in **bits** unless stated.

## 2. Time origin and sample index

A signal of `N` samples at `fs` has sample `k` (MATLAB 1-based) at
`t = (k-1)/fs`: **sample 1 is time zero**. Timestamps passed alongside a
signal must share that origin. Converting a timestamp back to a sample uses
one of two rules, and the function's help says which:

- **containing** sample, `floor(t*fs)+1` (`sparse_count_matrix`,
  `event_aligned_segments` by default, `spike_field_coherence`);
- **nearest** sample, `round(t*fs)+1` (`event_triggered_average`,
  `event_aligned_segments` with `'Anchor','nearest'`).

Detectors return times by the inverse rule (`phase_crossing_events`
interpolates between samples). The table in
[06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md) lists every case.

## 3. Bins and intervals

Every bin and exposure interval is **half-open**, `[left, right)`: an event
exactly on the right edge belongs to the next bin and is excluded from the
last one. Counting functions accept empty trains and **discard** nonfinite
timestamps (`spike_counts_edges` and everything built on it); a few
older functions **reject** them instead (`firing_rate`,
`interspike_intervals`, `spike_field_coherence`). Interval tables use
`start_s` and `stop_s`, with `stop_s` one sample after the last active
sample.

## 4. Array layouts

There is no single layout across the path, so check the help:

| Layout | Used by |
| --- | --- |
| samples x channels | `neuronal_read`, `multivariate_phase_surrogate`, `block_shuffle_surrogate`, `block_bootstrap_ci` (ordered rows) |
| channels x samples | `common_median_reference`, `bipolar_reference_lfp`, `current_source_density`, `spike_waveform_extraction`, `lfp_envelope_moments` |
| rows x samples, either via `'SampleDim'` | `event_aligned_segments` |
| observations x units | population, decoding and inference functions |
| time bins x units | `spike_history_design`, `coupling_filters`, `granger_causality` |
| one vector | spectral, phase, wavelet and most coupling functions |

Event-aligned outputs are **events x lags** (x rows). Waveform snippets are
**spikes x channels x samples**; templates **channels x samples**.

## 5. Explicit inputs

Functions use values and parameters passed to them; they do not read
`data` or other workspace variables, load files or change the path. The
CON²PHYS loaders, `a00_startup` and `con2phys.digest` live outside `path/`.

## 6. Randomness

Two conventions coexist. Bootstrap functions, `paired_signflip_test` and
`population_dimension_scaling` build their own `mt19937ar` stream from a
`seed` argument (default 42). Everything else that draws random numbers —
surrogates, permutation tests, subsampling, EEMD, CP-ALS,
`group_cross_validation` — uses the global stream: call `rng(seed)` first.
`decode_trials` records a seed but is deterministic.

## 7. Memory

Processing a whole LFP at once can take many GiB. Pass **blocks** of
channels and time read with `neuronal_read`; several functions cap their
input size explicitly (`bosc_detect`, `wavelet_coherence`,
`spike_waveform_extraction`, `spike_history_design`,
`gaussian_process_smoothing`). Do not assume a function is streaming or
memmap-ready.

## 8. Scope

Every function is an exploratory **primitive**. A function named after a
method implements the mathematical step stated in its help, not the full
published pipeline, and no numerical equivalence with the original papers
is claimed. The CON²PHYS LFP is 500 Hz with a **250 Hz Nyquist**: spike
detection and waveform functions need broadband data at the real acquisition
rate. For inference across animals, the animal is the experimental unit,
not millions of pseudoreplicated bins.

## Compatibility

Target: MATLAB R2019a or later. Many routines need the **Signal Processing
Toolbox** (`pwelch`, `periodogram`, `dpss`, `hilbert`, `butter`, `filtfilt`,
`findpeaks`, `mscohere`, `cpsd`, `resample`, `xcorr`). From the repository
root:

```matlab
run('matlab/neuronal_startup.m')
help Contents
run('matlab/tests/run_scientific_suite.m')   % real MATLAB and the toolbox required
```

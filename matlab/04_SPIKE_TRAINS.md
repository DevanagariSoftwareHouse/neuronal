# Spike-train counts, rates and correlograms (MATLAB)

[Índice](README.md) · [Anterior](03_SPIKES.md) · [Próximo](05_SPECTRA_OSCILLATIONS.md)

Sorted spikes enter this chapter as **timestamps in seconds**, one vector
per unit, on the recording's time origin. The primitives turn them into
counts on half-open bins, rates, interval distributions, correlograms,
trial variability and train distances. Alignment to external events is the
subject of [06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md); population
structure, of [08_POPULATION.md](08_POPULATION.md).

## 1. Counts on half-open bins

```matlab
edges = 0:.05:duration_s;
c = spike_counts_edges(unit_s, edges);                  % bins x 1
[c, centers_s, edges] = spike_bin_counts(unit_s, 0, duration_s, .05);
counts = spike_bins({unit_a_s, unit_b_s}, edges);       % bins x units
```

Every bin is `[left, right)`: a spike on the final edge is **excluded**, so
consecutive windows never count a spike twice. `spike_counts_edges` accepts
irregular increasing edges, empty trains and discards nonfinite timestamps.
`spike_bin_counts` builds equal bins from `start_s`, keeps only complete
bins (with a 1e-9 tolerance for decimal steps) and clips the last edge at
`stop_s`. `spike_bins` applies `spike_counts_edges` to a cell array of
units on shared edges. For a sparse unit x sample matrix on the LFP grid
use `sparse_count_matrix` ([06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md)).

## 2. Rates in intervals and trial windows

```matlab
rate_hz = firing_rate(unit_s, 0, duration_s);
windows = [stim_s(:) stim_s(:) + .5];                   % N x 2 seconds
x = trial_features({unit_a_s, unit_b_s}, windows);      % trials x units, Hz
```

`firing_rate` counts spikes in `[start_s, stop_s)` divided by the exposure;
unlike the counters above it **rejects** nonfinite timestamps instead of
discarding them. `trial_features` returns trial x unit rates for half-open
windows, `NaN` for rows whose window is nonfinite or of nonpositive length.
The resulting matrix is the usual input to decoders and noise correlations
([09_MODELS_DECODING.md](09_MODELS_DECODING.md)).

## 3. Intervals and correlograms

```matlab
isi_s = interspike_intervals(unit_s);
[lag_s, acg] = autocorrelogram(unit_s, 0, duration_s, .001, .05);
[lag_s, ccg] = crosscorrelogram(unit_a_s, unit_b_s, 0, duration_s, .001, .05);
```

`interspike_intervals` sorts and differences the train; duplicate times give
zero intervals and point to sample-precision issues. Both correlograms bin
the trains with `spike_bin_counts` and call `xcorr` on the counts up to
`round(max_lag_s/bin_s)` bins. The autocorrelogram keeps the zero-lag bin,
which includes self-pairs. In the cross-correlogram a **positive lag means
a follows b**. Neither applies trial, rate or shift-predictor corrections;
restrict the lag range rather than correlating whole recordings at all lags,
and use surrogates ([10_SURROGATES.md](10_SURROGATES.md)) before reading
peaks as synchrony.

## 4. Trial variability and train distance

```matlab
fano = spike_count_fano(trial_counts);                  % trials x units
d = victor_purpura_distance(train_a_s, train_b_s, 10);   % q in 1/s
```

`spike_count_fano` is the across-trial variance-to-mean ratio per column,
`NaN` where the mean is zero; mixing conditions inflates it.
`victor_purpura_distance` is the edit distance where inserting or deleting a
spike costs 1 and shifting it from `t` to `s` costs `q*abs(t-s)`; `1/q` is
the time scale at which a shift equals a deletion plus an insertion.

## Tests

From the repository root:

```matlab
run('matlab/tests/smoke_arsenal.m')            % bins, rates, ISI, correlograms, Fano
run('matlab/tests/smoke_imported_helpers.m')   % spike_bins, trial_features
run('matlab/tests/smoke_consensus_methods.m')  % Victor-Purpura distance
run('matlab/tests/check_arsenal_identities.m') % half-open counting, VP identities
```

Synthetic tests cover empty trains, endpoint exclusion, decimal bin widths
and known distances. Real-data rates still depend on sorting quality
([03_SPIKES.md](03_SPIKES.md)).

# Generic event-aligned analysis (MATLAB)

[Índice](README.md) · [Anterior](05_SPECTRA_OSCILLATIONS.md) · [Próximo](07_COUPLING.md)

The primitives in `path/` separate **event timestamp generation**, **signals
on the sample grid**, **event-aligned extraction**, **summaries**, and
**visualization**. Two kinds of input meet here and must not be confused:

- an **event** is a timestamp in seconds that defines lag zero: a stimulus
  onset, a behavioral transition, an oscillatory phase crossing, an envelope
  excursion, a ripple candidate, a TTL pulse — or a spike;
- a **signal** is anything sampled on the grid `t = (k-1)/srate`: binned
  spike counts, an LFP channel, a band-limited envelope, a phase.

Spikes can play either role. Aligning spike counts to stimuli gives a
raster and PSTH; aligning an LFP to spikes gives a spike-triggered average.
The same function serves both, because extraction does not care what the
rows mean. Any event expressed in seconds in the recording's time frame is
valid.

| Step | Function | Output |
| --- | --- | --- |
| Point events to grid | `sparse_count_matrix` | sparse label x sample counts |
| Events from phase | `phase_crossing_events` | interpolated crossing times |
| Events from an envelope | `amplitude_threshold_events` | anchor times, excursion table |
| Events from intervals | `ripple_candidate_events`, `oscillation_episode` | tables with `start_s`/`stop_s` |
| Extraction | `event_aligned_segments` | events x lags (x rows) |
| Summary of a signal | `event_triggered_average` | mean segment, lags, events used |
| Summary of point events | `peri_event_histogram` | bin centres, rate, trial counts |
| Display | `plot_event_aligned` | image, one row per event |

## Primer: what changes around an event?

Alignment replaces absolute time by time relative to an anchor. It does
not by itself remove a baseline, normalize a signal, or identify causation.
The same construction can ask about a voltage around stimuli, spike counts
around an envelope peak, or an envelope around behavioural transitions.

Let $x_c(t)$ be signal $c$, $t_k$ the time of event $k$, and $\tau_j$ a
relative lag. The aligned array and its average are

$$
X_{kjc}=x_c(t_k+\tau_j),\qquad
\overline X_{jc}=\frac{1}{K_j}\sum_{k\in\mathcal V_j}X_{kjc},
$$

where $\mathcal V_j$ contains events observed at lag $j$ and
$K_j=|\mathcal V_j|$. With boundary padding, $K_j$ may vary across lags.
This changes the contributing event population as well as the precision.
For a circular variable such as phase, use a circular summary of the
extracted angles; ordinary arithmetic averaging fails near the wrap point.

### Toy experiment: a response with a known latency

```matlab
run('matlab/neuronal_startup.m')
rng(31)
fs = 500;
t = (0:30*fs-1)'/fs;
event_s = (2:2:28)';
x = .5*randn(size(t));
for k = 1:numel(event_s)
    x = x + exp(-.5*((t-event_s(k)-.1)/.025).^2);
end
[segments, lag_s, meta] = event_aligned_segments( ...
    x, event_s, fs, [-.3 .4], [], 'Boundary', 'drop');
average = mean(segments, 1);
subplot(2,1,1)
imagesc(lag_s, 1:size(segments,1), segments);
xlabel('Lag (s)'); ylabel('Event'); colorbar
subplot(2,1,2)
plot(lag_s, average); xlabel('Lag (s)');
ylabel('Mean amplitude'); grid on
```

The generating waveform peaks 100 ms after each event; the average should
reveal that latency despite independent noise. Add random latency shifts
to the waveform while keeping the anchors fixed. The average broadens and
its peak falls even when each event's response amplitude is unchanged.
Therefore a smaller average peak need not mean weaker single-event responses.

### Controls that distinguish alignment from explanation

If events are maxima of `x`, aligning `x` to those events must produce a
central maximum by construction. This is useful for waveform description,
but it cannot establish an independent response. Similarly, overlapping
windows reuse samples; their rows cannot automatically be treated as
independent trials. Resample independent trials, blocks or animals while
preserving the event structure required by the question.

For a block beginning at global time `origin_s`, pass
`event_s - origin_s` to the extractor. Retain the original event IDs using
`meta.event_indices`, especially after dropping boundary events. For spike
counts, average counts and divide by bin exposure to obtain Hz; for LFP,
retain voltage units. A baseline subtraction should name its time window
and specify whether it is performed per event or after averaging.

**Exercise.** Include an event near time zero and compare default padding
with `'Boundary','drop'`. Plot the number of finite observations at every
lag. Explain why replacing missing values by zero biases the average.

## 1. Point events on the sample grid

```matlab
% Times and clusters may come from neuronal_memmap; any labels work.
[S, label_ids, meta] = sparse_count_matrix( ...
    timestamp.Data.x, cluster.Data.x, srate, data.n_lfp_samples);
```

`S` is **label row x recording sample**. The IDs in `label_ids` map its row
indices back to original labels (which need not be 1..N): spike clusters,
TTL lines or behavior codes. Recording bin `k` represents
`[(k-1)/srate, k/srate)`, the same grid as an LFP sampled at `srate` from
time zero, so counts and voltages align sample for sample. Events in the
same bin are counted, never coerced to logical values. The endpoint at
`n_samples/srate` is excluded; `meta.events_discarded` counts nonfinite and
out-of-recording times.

## 2. Align any signal to any event

```matlab
stim_s = [data.behavior.trials.stim_start];

% (a) Spike counts of one cluster: a raster and its PSTH.
row = find(label_ids == 7, 1);
assert(~isempty(row), 'Requested label is absent from this recording.');
[R, lag_s, info] = event_aligned_segments(S, stim_s, srate, [-1 1], row);
plot_event_aligned(R, lag_s, 'Scale','log1p');
psth_hz = mean(R, 1, 'omitnan') * srate;

% (b) Several LFP channels: channels x samples block, all rows.
lfp_block = double(neuronal_read(m, 1:60*srate, 1:4)).';
[V, lag_s] = event_aligned_segments(lfp_block, stim_s, srate, [-.5 .5]);
erp = squeeze(mean(V, 1, 'omitnan'));             % lags x channels

% (c) The same block in storage layout, without transposing.
[V2, lag_s] = event_aligned_segments(neuronal_read(m, 1:60*srate, 1:4), ...
    stim_s, srate, [-.5 .5], [], 'SampleDim', 1);
```

The output is **event x relative time bin x row**; with one row it is a
plain event x lag matrix. The lag zero column is the sample containing the
event timestamp (`floor(event_s*srate)+1`); `'Anchor','nearest'` uses
`round(event_s*srate)+1` instead. Endpoints of the window are included and
rounded to the sample grid. `info.event_indices` preserves the
correspondence with input events, and `info.rows` the selected rows.

Values are copied unchanged: counts keep multiple events per bin, voltages
keep their units, and the result is `double`. By default partial windows
are retained, with unavailable samples set to `NaN` (rather than zero). Use
`'Boundary','drop'` to discard incomplete windows. Without an explicit `SampleDim`, a vector signal is one
row whatever its orientation. An explicit `SampleDim` takes precedence,
including a channels x 1 block containing only one time sample. A sparse label x sample matrix stays sparse;
only the requested rows' event x lag slices become dense, so for thousands
of clusters loop over rows instead of requesting them all at once. Passing
`m.Data.x` of a memory map reads the whole array: pass bounded blocks from
`neuronal_read` ([01_STORAGE.md](01_STORAGE.md)).

## 3. Oscillatory phase and amplitude events

```matlab
% The LFP must be bandpassed before extracting its analytic phase/envelope.
filtered = bandpass_lfp(lfp, srate, [6 10]);
[phase, amp] = analytic_phase(filtered);

% Rising target-phase crossings; theta cycles ~8 Hz in this example.
phase_s = phase_crossing_events(phase, srate, 0, .06);
[Rphase, lag_s] = event_aligned_segments(S, phase_s, srate, [-.2 .2], row);

% Envelope excursions: threshold must be scientifically justified.
[peak_s, envelope_events] = amplitude_threshold_events( ...
    amp, srate, median(amp) + 3*std(amp), 'Anchor','peak', ...
    'MinDuration',.02);
[Ramp, lag_s] = event_aligned_segments(S, peak_s, srate, [-.2 .2], row);

% The envelope itself, around its own peaks (rows of a vector signal: 1).
[Aenv, lag_s] = event_aligned_segments(amp, peak_s, srate, [-.2 .2]);
```

`phase_crossing_events` detects forward crossings modulo `2*pi` and
interpolates between samples; phase quality and sufficient sampling (less
than `pi` radians per sample) are prerequisites, and `min_separation_s`
enforces a greedy refractory spacing. `amplitude_threshold_events` reports
maximal runs of `envelope >= threshold` as `start_s`, `stop_s` (one sample
after the last active sample), `peak_s`, `peak_amplitude` and `anchor_s`,
with onset/peak/midpoint alignment choices. Neither function alone
validates neural oscillations. Discard filter edges before detecting
events ([02_PREPROCESSING.md](02_PREPROCESSING.md)).

## 4. Interval events: ripples and episodes

```matlab
% Example; the default ripple band requires Nyquist > 200 Hz.
ripples = ripple_candidate_events(lfp, srate);
if ~isempty(ripples)
    [Rripple, lag_s] = event_aligned_segments( ...
        S, ripples.peak_s, srate, [-.25 .25], row);
    plot_event_aligned(Rripple, lag_s);
end

% BOSC episodes are tables too: align to onsets.
res = bosc_detect(lfp(1:60*srate), srate, 4:2:30);
onsets_s = res.episodes{res.frequency_hz == 8}.start_s;
```

Interval detectors return `start_s`/`stop_s`, so the anchor is a choice:
`peak_s` (envelope maximum), `start_s`, or an explicitly stated midpoint
`(start_s + stop_s)/2`. Midpoint alignment is **not** peak-envelope
alignment. Use appropriate event markers (and independent validation) for
any ripple physiology claims ([05_SPECTRA_OSCILLATIONS.md](05_SPECTRA_OSCILLATIONS.md)).

## 5. Spikes as events: triggered averages

```matlab
unit_s = timestamp.Data.x(cluster.Data.x == 7);
[sta, lag_s, used] = event_triggered_average(lfp, unit_s, srate, .2, .2);

% Equivalent explicit form, keeping every segment for inference.
[seg, lag_s] = event_aligned_segments(lfp, unit_s, srate, [-.2 .2], 1, ...
    'Anchor','nearest','Boundary','drop');
sta2 = mean(seg, 1).';
```

`event_triggered_average` averages a finite vector around any events; with
spike times and an LFP it is the spike-triggered average. It uses the
**nearest** sample and drops incomplete windows; `used` counts the events
retained, and the average is `NaN` when none remains. It accumulates one
window at a time, so working memory does not grow as events x lags.
Keep the segments when
the spread across events matters. Shared stimulus drive and common trial
locking are **not** removed: compare with shuffled or jittered spikes
([10_SURROGATES.md](10_SURROGATES.md)).

## 6. Peri-event histograms from timestamps

```matlab
[centers_s, rate_hz, trial_counts] = peri_event_histogram( ...
    unit_s, stim_s, -1:.02:1);
```

When no sample grid is needed, `peri_event_histogram` counts point events
relative to each anchor on explicit half-open edges (irregular widths
allowed) and returns bin centres, the across-event mean rate in Hz and the
event x bin counts. Empty trains are accepted and nonfinite timestamps
discarded, as in `spike_counts_edges`. Neighbouring events and their
windows may overlap and are not independent trials.

## 7. Timestamp-to-sample conventions

| Function | Sample for time `t` | Note |
| --- | --- | --- |
| `sparse_count_matrix` | `floor(t*fs)+1` | containing bin, half-open |
| `event_aligned_segments` | `floor(t*fs)+1`, or `round(t*fs)+1` | `'Anchor'` option |
| `event_triggered_average` | `round(t*fs)+1` | nearest sample |
| `spike_field_coherence` | `floor(t*fs)+1` | containing sample |
| `spike_field_ppc` | interpolated phase | no rounding |
| `phase_crossing_events`, `amplitude_threshold_events` | inverse: `t = (k-1)/fs` | sample 1 is 0 s |

The two anchors differ by at most one sample. State which one an analysis
used; mixing them shifts phase estimates by up to `2*pi*f/fs`.

## 8. Autocorrelation

An existing, independent primitive already covers spike-train
autocorrelation from timestamps:
`autocorrelogram(spike_times, start_s, stop_s, bin_s, max_lag_s)`.
Avoid full-recording, unrestricted `xcorr` if only short lags matter
([04_SPIKE_TRAINS.md](04_SPIKE_TRAINS.md)).

## 9. Cropped recordings and shared clocks

An event timestamp and its aligned signal must use the same time origin.
For a block starting at original sample `first_sample`, rebase timestamps:

```matlab
first_sample = 5001;
block = neuronal_read(m, first_sample:first_sample+4999, 1:4);
block_start_s = (first_sample-1)/srate;
local_events_s = stim_s - block_start_s;
[segments, lags_s, info] = event_aligned_segments( ...
    block, local_events_s, srate, [-.2 .2], [], ...
    'SampleDim',1, 'Boundary','drop');
original_event_positions = info.event_indices;
```

This subtraction assumes synchronized clocks and no acquisition gaps. A
sampling rate alone does not establish synchronization. With separate devices,
first estimate the clock transformation from shared markers. For chunked
processing include overlap sufficient for the window and filter support; assign
each event to exactly one core chunk to avoid counting it twice.

`info.valid_bins` marks whether the requested sample exists in the recording;
it does not certify that the signal value is finite or artifact-free. Apply an
artifact mask separately. NaN padding means unavailable data; zero counts mean
an observed bin with no event. Retain the valid-event denominator at each lag.

## 10. Summaries depend on the measured quantity

| Aligned quantity | Summary | Units / interpretation |
| --- | --- | --- |
| Counts per grid bin | `mean(R,1,'omitnan') * srate` | Events/s; only for this bin width |
| Voltage or envelope | `mean(V,1,'omitnan')` | Original signal units; no multiplication by sampling rate |
| Wrapped phase | `angle(mean(exp(1i*P),1,'omitnan'))` | Circular mean in radians |
| Unit phase vectors | `abs(mean(exp(1i*P),1,'omitnan'))` | Resultant length; descriptive phase concentration |

Use an explicit `'Scale','linear'` with a meaningful `'ValueLabel'` when
plotting continuous signals. Auto scale cannot distinguish integer-valued
voltages from counts. A display transform must never be used as a rate estimate.
For phase, the arithmetic mean of angles near -pi and pi is misleading;
resultant length also needs a bias/dependence-aware null before inference.

Aligning an envelope to its own detected maxima guarantees a central peak by
construction. This is a useful detector diagnostic, but is not evidence of
cross-signal coupling. Separate the detection and measurement questions and
apply the same event-selection procedure to the null analysis when required.

## 11. Events, trials and independent experimental units

An extracted row is an **event**, not automatically an independent trial.
Overlapping windows can reuse the same samples; multiple events can belong to
one trial, session or animal. Preserve those identifiers alongside
`info.event_indices` before any averaging or resampling.

For a comparison between simultaneously recorded areas, extract both on the
same events and use a common valid-event mask. Compute the paired difference
within the experimental unit, then estimate uncertainty on those differences.
Dropping boundary windows independently for each area can silently destroy the
pairing. Across-animal conclusions require an animal-level estimand and a
resampling design that respects the nested observations; more event rows do
not create more independent animals. Continue with [surrogates](10_SURROGATES.md)
for null hypotheses and [inference](11_INFERENCE.md) for uncertainty.

## 12. Migration from spike-specific names

| Existing name | Preferred generic name | Compatibility behavior |
| --- | --- | --- |
| `spike_raster_sparse` | `sparse_count_matrix` | Keeps `spikes_input`, `spikes_kept`, `spikes_discarded` |
| `event_aligned_raster` | `event_aligned_segments` | One row, containing anchor, `info.cluster_row` |
| `spike_triggered_average` | `event_triggered_average` | Nearest anchor, full windows, column-vector outputs |
| `plot_event_raster` | `plot_event_aligned` | Explicit log1p display and spike-count colorbar |

The old functions remain thin compatibility wrappers. Use the generic names
in new code. This migration does not rename physiological operations such as
spike sorting, refractory violations or waveform quality: their assumptions
remain specific to spikes.

## Tests

From the repository root:

```matlab
run('matlab/tests/test_event_alignment.m')
% Or the full MATLAB scientific test suite:
run('matlab/tests/run_scientific_suite.m')
```

Synthetic tests cover repeated events per bin, label mapping, half-open
recording boundaries, partial event windows, drop mode, non-grid
timestamps, all-row extraction, dense channels x samples and samples x
channels layouts, vector orientation, containing versus nearest anchors,
the triggered average against an explicit loop, phase crossings, amplitude
threshold excursions, interval centering, singleton sample layouts and
compatibility metadata. `plot_event_aligned` is not
exercised (no graphics in CI).

# Generic event-aligned spike analysis (MATLAB)

The primitives in `path/` separate **spike binning**, **event timestamp
generation**, **event-aligned extraction**, and **visualization**. Any event
expressed in seconds in the recording's time frame is valid: stimulus
onsets, oscillatory phase crossings, amplitude excursions, ripple
candidates, behavioral transitions, or experimentally defined timestamps.

## 1. Spike counts as a sparse matrix

```matlab
% Times and clusters may come from neuronal_memmap.
[S, cluster_ids, meta] = spike_raster_sparse( ...
    timestamp.Data.x, cluster.Data.x, srate, data.n_lfp_samples);
```

`S` is **cluster row x recording sample**. The IDs in `cluster_ids`
map its row indices back to original cluster labels (which need not be
1..N). Recording bin `k` represents `[(k-1)/srate, k/srate)`.
Spikes in the same bin are counted, never coerced to logical values.
The endpoint at `n_samples/srate` is excluded.

## 2. Align to any timestamped event

```matlab
stim_s = [data.behavior.trials.stim_start];
cluster_row = find(cluster_ids == 7, 1);
[R, lag_s, info] = event_aligned_raster( ...
    S, stim_s, srate, [-1 1], cluster_row);
plot_event_raster(R, lag_s);
psth_hz = mean(R, 1, 'omitnan') * srate;
```

`R` is **event x relative time bin** for one cluster; the lag zero
column is the recording bin containing the event timestamp
(`floor(event_s*srate)+1`). Endpoints of `[-1 1]` are included and
rounded to the sample grid. The `info.event_indices` vector preserves
the correspondence with input events.

By default, partial windows are retained, with unavailable samples set
to `NaN` (rather than counting them as zero). Use
`'Boundary','drop'` to discard incomplete windows. The full
cluster x recording matrix remains sparse; only the requested cluster's
event x lag slice becomes dense. To process all neurons, loop over
`1:numel(cluster_ids)` and extract each individually.

## 3. Oscillatory phase and amplitude events

```matlab
% The LFP must be bandpassed before extracting its analytic phase/envelope.
filtered = bandpass_lfp(lfp, srate, [6 10]);
[phase, amp] = analytic_phase(filtered);

% Rising target-phase crossings; theta cycles ~8 Hz in this example.
phase_s = phase_crossing_events(phase, srate, 0, .06);
[Rphase, lag_s] = event_aligned_raster(S, phase_s, srate, [-.2 .2], 1);

% Envelope excursions: threshold must be scientifically justified.
[peak_s, envelope_events] = amplitude_threshold_events( ...
    amp, srate, median(amp) + 3*std(amp), 'Anchor','peak', ...
    'MinDuration',.02);
[Ramp, lag_s] = event_aligned_raster(S, peak_s, srate, [-.2 .2], 1);
```

`phase_crossing_events` detects forward crossings modulo `2*pi`
and interpolates between samples; phase quality and sufficient sampling
are prerequisites. `amplitude_threshold_events` reports contiguous
threshold excursions, with onset/peak/midpoint alignment choices.
Neither function alone validates neural oscillations.

## 4. Align to ripple candidates

```matlab
% Example; ripple_candidate_events requires Nyquist > 200 Hz.
ripples = ripple_candidate_events(lfp, srate);
% Candidate table provides start_s and stop_s, not peak timestamps.
ripple_mid_s = (ripples.start_s + ripples.stop_s)/2;
if ~isempty(ripple_mid_s)
    [Rripple, lag_s] = event_aligned_raster( ...
        S, ripple_mid_s, srate, [-.25 .25], 1);
    plot_event_raster(Rripple, lag_s);
end
```

Midpoint alignment is **not** peak-envelope alignment. Use appropriate
event markers (and independent validation) for any ripple physiology
claims.

## 5. Autocorrelation

An existing, independent primitive already covers spike-train
autocorrelation from timestamps:
`autocorrelogram(spike_times, start_s, stop_s, bin_s, max_lag_s)`.
Avoid full-recording, unrestricted `xcorr` if only short lags matter.

## Tests

From the repository root:

```matlab
run('matlab/tests/test_event_alignment.m')
% Or the full MATLAB scientific test suite:
run('matlab/tests/run_scientific_suite.m')
```

Synthetic tests cover repeated spikes per bin, cluster-label mapping,
half-open recording boundaries, partial event windows, drop mode,
non-grid timestamps, phase crossings, amplitude threshold excursions,
and ripple interval centering.

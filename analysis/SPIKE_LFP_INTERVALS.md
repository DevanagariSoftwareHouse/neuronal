# Spike/LFP analysis over frequency and time intervals

Run from the repository root:

```matlab
run analysis/a00_startup.m  % only if data is not already prepared
run analysis/t03_spike_lfp_intervals.m
```

The script itself calls `a00_startup` only when `data` is absent/empty. That
existing startup contains user-specific paths and clears the workspace; it is
not changed here. Configuration is defined **after** startup. The script finds
the repository from its own location and adds `matlab/path` explicitly.

## Scope and configuration

Default: session 1, channel 1 of each LFP area, temporal levels `0:6`, frequency
levels `1:3`, frequency overlap 0.5, temporal overlap 0. This is an initial small
run. To reproduce the full bank in the draft, edit the configuration section:

```matlab
cfg.sessions = 1:numel(data);
cfg.channels = [];            % all channels
cfg.time_levels = 0:15;
cfg.frequency_levels = 0:7;
```

Edit these assignments **inside the script**; running it resets `cfg`.
The full bank is expensive: each time level can repeat the same spike in a
different window, and each band/channel produces its own summaries. Outputs
are not independent observations merely because their interval IDs differ.
The level-0 full-spectrum frequency interval is skipped by default because its
filter is identity. Lowpass/highpass bands are retained but flagged separately
from bandpass candidates; their Hilbert phase is not necessarily the phase of
one narrowband oscillation. Even a bandpass flag does not guarantee narrowness.

The script uses CPU explicitly. `filter_do`'s default GPU policy would gather
a GPU signal for each filter and then send it back; the script avoids that
roundtrip and does not create an unused parallel pool. Filter one full channel
per band, then reuse its analytic signal for every time window. Whole-session
filtering/Hilbert still needs full-channel buffers; this is not out-of-core
filtering. No filtered waveforms or per-window raw spike arrays are persisted.

## Input contracts and clocks

- Each LFP mapping has one field `x` with shape `[n_lfp_samples,n_channels]`.
  Shape is read from `memmapfile.Format`, without reading all channels.
- Spike times must share the first LFP sample's time origin. Set
  `spike_time_scale` (e.g. 1e-3 for milliseconds), then subtract
  `spike_time_origin_seconds` to align recordings. The default assumes seconds
  relative to LFP time zero; the script cannot infer correct acquisition units.
- Cluster IDs are mapped to columns in `waveform_id` order. Duplicate waveform
  IDs fail. Mixed integer classes are normalized to double only after checking
  finite integral values strictly within the exact integer range.
- Unmapped clusters and nonfinite/out-of-session times are reported separately.
- Windows use `[t0,t1)`. A spike at `N/fs` is outside the recording. The LFP
  lookup uses `floor(time*fs)+1`, clamped only at N to absorb endpoint roundoff
  for already validated times. This is previous-sample lookup, not interpolation.

## Computation

`spike_interval_plan` groups/sorts spikes once per unit. Vectorized binary
searches locate both bounds of every window, including overlapping/unsorted
windows. Counts are calculated once per session. The plan is reused across
areas, channels and bands; no full spike mask is rebuilt for each window.

`spike_interval_features` samples the complex analytic signal at each spike,
forms unit phasors, and computes prefix sums of their real/imaginary parts,
amplitudes and validity indicators. Differences of prefixes produce window
summaries. The cost per band is O(spikes + windows*units), in addition to
filtering/Hilbert. No `storage_append` calls occur: the current append backend
would reread and rewrite accumulated artifacts.

Zero-phase Butterworth filtering is the default offline policy. The stored
filter descriptor and configuration identify that choice. `edge_seconds=1`
and `edge_cycles=3` define exclusion at each session end:
`max(edge_seconds,edge_cycles/low_frequency)`, using the upper cutoff when the
lower cutoff is zero. This is a **heuristic**, not a validated settling-time
bound for the IIR filter or Hilbert transform. If no interior remains, the band
is skipped with a warning. Validate padding/settling and edge sensitivity before
using results for inference. Analytic amplitudes must exceed `amplitude_floor`
and be finite. Invalid phase observations do not enter phase/amplitude means.

## Outputs

Each execution creates a fresh run directory under
`data/derived/spike_lfp_intervals`, printed at start and completion. This avoids
mixing results from incompatible settings or silently overwriting earlier runs.
The selected storage backend defaults to HDF5. Outputs preserve declared types.

| Key suffix | Shape/type | Meaning |
| --- | --- | --- |
| `session_ID/windows` | W x 6 double | Time bounds, level, overlap, inclusive LFP sample bounds |
| `session_ID/frequency_bands` | F x 5 double | Frequency ID, low/high Hz, level and overlap (including skipped candidates) |
| `session_ID/spike_count` | W x units uint32 | All mapped valid recording spikes per window |
| `.../phase_mean` | W x units single | Circular mean in radians; NaN for empty/undefined direction |
| `.../phase_strength` | W x units single | Mean resultant length, 0–1; NaN for empty windows |
| `.../amplitude_mean` | W x units single | Mean analytic amplitude at phase-valid spikes |
| `.../phase_count` | W x units uint32 | Number of observations contributing to those summaries |
| `.../phase_exposure_seconds` | W x 1 double | Window duration after temporal edge clipping |
| `.../complete` | scalar uint8 | Written after all artifacts for that band/channel succeed |

Band keys include session, area, channel, frequency ID, method, order and phase
policy. Metadata stores the frequency interval, complete filter descriptor,
waveform ID column order, clock policy, configuration and edge exclusion.
Exposure accounts for temporal clipping only, not amplitude-invalid samples.
Original spike counts have no band-specific exclusion; use `phase_count` as the
sample count for phase summaries. Mean amplitude is at spikes, not average LFP
amplitude or power over the entire time bin.

A session completion marker is written after all selected areas/channels and
eligible bands. Missing band/session markers indicate an interrupted run.
There is no automatic resume/overwrite. See `matlab/STORAGE.md` for persistence
and crash-recovery limitations. Summaries are descriptive: small spike counts
bias resultant length (one spike gives 1); no p-values or surrogates are implied.

## Memory and validation

The script estimates plan/result memory before allocation and stops above
`max_summary_mib`. This is a planning estimate, not a process RAM limit: LFP,
spike/sort arrays, MATLAB struct overhead and filter buffers add memory. Results
are held for one band/channel and saved as complete matrices, then released;
there is no frequency-by-channel-by-window array resident in RAM. Reduce time
levels or selected units if the summary estimate is too large.

Run contracts with:

```matlab
addpath('matlab/path'); addpath('matlab/tests');
test_spike_interval_features
```

Tests compare prefix reductions with explicit spike masks, cover duplicate
spikes, boundary membership, circular wrap/cancellation, excluded spikes,
nonfinite analytic samples, empty units, overlapping dyadic windows, and (when
Signal Processing Toolbox is available) filtering/Hilbert/HDF5 integration.
They do not validate the biological interpretation or acquisition time origin.

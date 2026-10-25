# Disk-backed window/filter measurements

From the repository root, initialize the catalog, then run:

```matlab
run analysis/a00_startup.m
cfg = struct();
cfg.sessions = 1;
cfg.channels = 1;                 % [] selects all channels
cfg.time_levels = 0:15;           % match the spike-window producer exactly
cfg.time_overlap = 0.5;
cfg.frequency_levels = 0:7;
cfg.methods = {'butterworth'};
cfg.orders = 4;
run('analysis/+con2phys/t03_session_window_filter.m')
```

The script does not call startup, clear the workspace, load session_windows.mat,
start a pool, or use a GPU. It keeps one full CPU channel and one configuration's
intermediates and measurements in RAM. Filtering and Hilbert transforms still act
on the complete channel; this is bounded across configurations, not streaming
across time. Each completed configuration is written immediately to disk.

Outputs default to `data/derived/session_window_filter_v2/session_<id>/`:

- `geometry.mat`: top-level first, last, level, window, overlap and metadata.
- `catalog.mat`: ordered filter designs, frequency intervals, methods and orders.
- `<area>_chNNN.mat`: seven double matrices [windows x configurations], small
  metadata, and a logical completed vector. Geometry is not repeated per column.

Window ordering is level order followed by window index, matching the current
`t01.time_interval_windowing.m` defaults (0:15, overlap 0.5). If a previous count
bank used different settings or ordering, set these explicitly before joining.
Frequency geometry spans 0 to Fs/2, including identity, lowpass and highpass
endpoints. Unlike the old script, bands touching Nyquist are not discarded.
Odd FIR orders are skipped. Equiripple transition width defaults to 20% of band
width, capped to half the available DC/Nyquist margins. This is a design policy,
not a guarantee of suitable attenuation; inspect responses before inference.

The default application is explicitly causal, matching filter_do's default.
Set cfg.phase='zero' to use forward-backward filtering in a NEW output directory.
Derivatives use diff(unwrap(angle(hilbert(filtered)))) scaled by Fs and Fs^2.
They belong to their later sample and may use samples preceding a window's left
boundary. No edge rejection or low-amplitude phase mask is applied. Broad or
identity bands should not automatically be interpreted as single oscillators.

Resume reruns the same script: columns marked completed are skipped. An unfinished
column is fully overwritten before being marked complete. Zeros in incomplete
columns are placeholders, not observations. Initial files are staged and renamed.
This is not transactional protection against power loss or filesystem corruption.
Use only ONE process per output directory; concurrent writers are unsupported.

Resume compares source path, size, modification timestamp, map format and offset,
geometry settings, filter designs, phase policy, MATLAB version, and pipeline/
dependency source text. Changed inputs require a new output directory. Source
metadata is not a cryptographic content hash: do not edit raw data during a run
or preserve old timestamps when replacing it.

```matlab
m = matfile('data/derived/session_window_filter_v2/session_00001/lfp_1_ch001.mat');
assert(m.completed(1,2));
x = m.mean_amplitude(1:100,2);     % partial read, no whole result load
```

Seven double features require 56 * n_windows * n_configs uncompressed bytes per
channel. The script reports this estimate before processing. Disk-backed writing
does not reduce the final bank size; start with a small selection of channels,
levels and methods before expanding.

Validation:

```matlab
addpath('matlab/tests');
test_session_window_filter_disk
```

The regression uses synthetic signals and both mapped orientations, checks direct
identity-filter measurements, recovers an incomplete column, preserves completed
columns, and rejects incompatible resume settings. It requires MATLAB and Signal
Processing Toolbox. R2019a syntax was checked with MISS_HIT; execution of this
regression and real-data validation require a MATLAB installation.

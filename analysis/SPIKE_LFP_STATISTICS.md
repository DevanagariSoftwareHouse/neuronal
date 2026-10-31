# Spike/LFP statistics and figures — CON²PHYS session 01

Adds a **descriptive** stage after the completed `t03_spike_lfp_intervals.m` run.
Requires MATLAB R2019a with the existing `neuronal/matlab/path` storage API.
No raw electrophysiology recording is loaded; processing reads HDF5
results of a single session and writes independent summary files.

From the repository root in MATLAB:

```matlab
addpath('matlab/path'); addpath('matlab/tests');
test_spike_lfp_summarize_band
run('analysis/t04_spike_lfp_statistics.m')
run('analysis/t05_spike_lfp_figures.m')
run('analysis/t06_spike_lfp_temporal_figures.m')
```

Edit `cfg.run_root` in both t04 and t05 if analyzing a different run.
`cfg.min_spikes_per_unit = 10` sets the descriptive neuron eligibility
threshold. No significance threshold or p-value is calculated.

Outputs inside `<run_root>/statistics/session_01/`:

- `band_statistics.mat`: one row per area/channel/band; along with the
  original frequency and temporal window tables and analysis policy.
- `band_statistics.csv`: exportable numerical table.
- `figures/mean_ppc_lfp_*.png`: channel x frequency maps.
- `figures/mean_plv_lfp_*.png`: channel x frequency maps.
- `figures/eligible_fraction_lfp_*.png`: data coverage.
- `figures/ppc_frequency_profiles.png`: frequency-level-separated plots.
- `figures/pooled_phase_lfp_*.png`: descriptive polar examples.
- `figures/temporal_lfp_*.png`: descriptive multilevel time dynamics for one
  channel and selected band (overlaps are not independent replications).

**Statistical contracts.** The one full-session temporal window (level 0)
is used to avoid counting overlapping dyadic windows as independent
replications. Each neuron is one entry in the channel-band summary, and
channels are presented descriptively—not as independent experimental
subjects. Frequency intervals overlap, too. PPC is
`(n * resultant_length^2 - 1) / (n - 1)` and may be negative. The formula
is unbiased for pairwise phase consistency under i.i.d. event-phase sampling;
spike history and behavior may violate those assumptions. The pooled phase
vector is spike-count-weighted and may cancel neuron-specific preferences.

**Quality and limitations.** A completed `.store` means a file exists, not
that its science is valid. The statistics code checks count consistency and
reports units with invalid summary values. It does not validate recording
clocks, artifacts, channel referencing, filter edge settling, power, or
refractory/autocorrelation effects. For inferential comparisons across brain
areas, use sessions/animals as clusters and appropriate surrogates or
hierarchical models. Avoid Rayleigh tests on aggregated overlapping windows.

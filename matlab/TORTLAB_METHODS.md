# Tortlab-inspired minimal and macro functions

The following additions to `matlab/path` reuse the existing neuronal low-level
functions instead of copying external repository source code.

| File | Level | Signature | Upstream |
| --- | --- | --- | --- |
| `phase_phase_coupling.m` | Minimal | `[strength,preferred_phase,phase_difference] = phase_phase_coupling(phase_a,phase_b,n,m)` | [tortlab/phase_phase](https://github.com/tortlab/phase_phase) |
| `phase_binned_plv.m` | Minimal | `[plv,phase_centers,counts] = phase_binned_plv(phase_a,phase_b,reference_phase,nbins,min_count)` | [tortlab/Phase-Locking-Value---Modulation-Index](https://github.com/tortlab/Phase-Locking-Value---Modulation-Index) |
| `pac_comodulogram.m` | Macro | `[mi,low_centers,high_centers] = pac_comodulogram(signal,srate,phase_bands,amplitude_bands,nbins)` | [tortlab/phase-amplitude-coupling](https://github.com/tortlab/phase-amplitude-coupling) |
| `assembly_mp_significance.m` | Macro | `[significant,threshold,eigenvalues] = assembly_mp_significance(spike_counts)` | [tortlab/Cell-Assembly-Detection](https://github.com/tortlab/Cell-Assembly-Detection) |

The phase-binned PLV gives **per-bin locking**, not the modulation-index statistic
implemented by the source repository; adding that metric should be a separate,
testable primitive. The MP cutoff assumes independent standardized activity and
is only a screening threshold, **not** a validated null for autocorrelated spikes.
Comodulogram MI is descriptive and needs edge exclusion, controls for common
source and nonsinusoidal waveforms, and surrogate calibration.

All are clean-room implementations attributed to upstream scientific methods.
Do not assert numerical equivalence with upstream code without reference tests.

## Synthetic tests

```matlab
addpath('matlab/path');
addpath('matlab/tests');
test_tortlab_minimal_macro();
```

Requires the Signal Processing Toolbox. Tests are supplied but have not been
executed by the GitHub connector environment.

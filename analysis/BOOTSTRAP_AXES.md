# Bootstrap by axis: analysis scripts

**Storage dimension is not the unit of inference.** In particular, trials and
LFP samples from the same animal do not become independent animals by
flattening an array. Define the estimand and sampling/assignment design first.

| Script | Storage axes | Resampled unit | Target |
| --- | --- | --- | --- |
| `b00_bootstrap_axes.m` | animal × trial × time | pooled trial (incorrect comparator) vs animal | mean across animals |
| `b01_bootstrap_hierarchical_axes.m` | cell array of trials by animal | animal, optionally trial within animal | mean of animal means |
| `b02_bootstrap_paired_axes.m` | animal × condition | animal row, both conditions together | paired mean difference |
| `b03_bootstrap_temporal_axes.m` | time | IID samples (incorrect comparator) vs contiguous circular blocks | stationary time-series mean |

All scripts are **self-contained**, seeded, use **synthetic data only**, print
a table and draw a histogram. Run from MATLAB with
`run('analysis/b00_bootstrap_axes.m')`, etc. No real CON²PHYS data are read.

## Interpretation and limits

- Animal bootstrap addresses inference to a population of independent animals;
  with only 18 animals, percentile interval coverage may be imperfect.
- Two-stage animal/trial resampling estimates uncertainty under the assumed
  nested sampling design. Do not resample trials independently across animals.
- Paired experimental conditions must travel together in the same animal draw.
- Channels simultaneously recorded and clusters observed over shared trials may
  be **crossed** or correlated, not a simple animal→neuron→trial hierarchy.
- Circular blocks assume sufficiently stationary dependence; block length is a
  tuning parameter. For event-locked LFP effects, summarize per trial/animal
  and resample at the appropriate independent level.
- Bootstrap is not a substitute for randomization-based tests when the
  experimental assignment mechanism is the inferential target.

The `bNN_bootstrap_*.m` names denote **analysis examples**, not toolbox
primitives. Reusable method implementations belong in `matlab/path`.
These scripts have not been executed in MATLAB here.

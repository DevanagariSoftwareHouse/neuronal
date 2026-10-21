# CON²PHYS bootstrap: axis × interval method

These `b10`–`b13` examples use **synthetic observations** and do not access the real recordings. Run after adding `matlab/path` to the MATLAB path.

| Script | Resampling axis | Interval |
| --- | --- | --- |
| `b10_bootstrap_animal_percentile.m` | independent animal | percentile |
| `b11_bootstrap_animal_bca.m` | independent animal | BCa |
| `b12_bootstrap_paired_animal_percentile.m` | matched animal condition pair | percentile |
| `b13_bootstrap_paired_animal_bca.m` | matched animal condition pair | BCa |

Call examples as `con2phys.b10_bootstrap_animal_percentile` after adding the `analysis` directory to the path. Scripts may also be run by their file paths.

**Inferential target:** population mean across independently sampled animals, or population mean of within-animal treatment–baseline differences. Paired conditions must share the same selected animal index. The paired examples resample the difference vector, which is equivalent for a mean contrast.

**Do not** resample individual LFP time samples, channels, clusters or trials as if they were independent animals. Hierarchical trial resampling and temporal block resampling are separate designs. BCa relies on animal-level jackknife replicates and may be unstable with small animal counts.

**Comparison:** use identical synthetic input data and, where feasible, common bootstrap indices when comparing interval methods. The standalone examples intentionally use different seeds and simulated datasets and are not a controlled head-to-head comparison.

**Status:** examples have not been executed in MATLAB in this environment.

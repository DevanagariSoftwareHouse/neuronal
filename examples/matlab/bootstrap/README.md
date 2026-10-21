# Bootstrap and resampling: MATLAB simulations

Standalone educational scripts using **synthetic data**, one per method. The scripts locate `matlab/path` relative to their own file location; run them from any MATLAB working directory. Each script fixes its RNG seed, prints an estimate and interval, and displays a plot.

| Script | Method | Simulated data |
| --- | --- | --- |
| `classical_bootstrap_demo.m` | IID bootstrap: percentile/basic/BCa | Gaussian observations |
| `jackknife_demo.m` | Leave-one-out jackknife | Gaussian observations |
| `bayesian_bootstrap_demo.m` | Rubin Bayesian bootstrap | Gaussian observations; Dirichlet weights |
| `balanced_bootstrap_demo.m` | Balanced bootstrap | Gaussian observations |
| `wild_bootstrap_demo.m` | Wild bootstrap | Heteroskedastic linear regression |
| `hierarchical_bootstrap_demo.m` | Hierarchical bootstrap | 18 animals, unequal trial counts |
| `block_bootstrap_demo.m` | Circular moving-block and stationary bootstrap | AR(1) + 8 Hz synthetic signal |
| `subsampling_demo.m` | Without-replacement subsampling | Gaussian observations |

## Running

From the repository root:

```matlab
run('examples/matlab/bootstrap/classical_bootstrap_demo.m')
run('examples/matlab/bootstrap/hierarchical_bootstrap_demo.m')
```

Or open a script in MATLAB and select **Run**. The scripts rely on functions in `matlab/path`; the functions use `quantile` and other MATLAB statistical routines.

## Interpretation

A displayed interval is a **single simulated dataset's** interval, not evidence of nominal coverage. The Bayesian bootstrap produces credible intervals; the other methods target confidence intervals under their respective assumptions. Temporal correlation, hierarchical independence, regression model specification, block length and subsample size can invalidate naive interpretations. For scientific inference, run many independent synthetic datasets and estimate repeated-sampling coverage.

These examples have been added to GitHub but **not executed in MATLAB** in this session.

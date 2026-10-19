# Resampling extensions (draft)

These functions are in `matlab/path` and assume the MATLAB Statistics and Machine Learning Toolbox for `quantile`. Add the directory to the MATLAB path.

| Function | Resampling unit | Notes |
| --- | --- | --- |
| `bayesian_bootstrap_ci` | IID rows, random Dirichlet weights | `statfun(x,w)` must implement weighted statistic; returns credible intervals |
| `balanced_bootstrap_ci` | IID rows | Each observation appears exactly B times across B replicates |
| `wild_bootstrap_ci` | Independent regression rows | Fixed-design OLS; Rademacher/Mammen residual multipliers, HC2 adjustment |
| `hierarchical_bootstrap_ci` | Nested independent top-level units | Recursive cell levels; original two-level numeric-cell API preserved |
| `block_bootstrap_ci` | Ordered time-series rows | Existing circular blocks; `stationary=true` selects random-length blocks |

Examples:

```matlab
addpath('matlab/path')
x=(1:20)';
[ci,theta,draws]=bayesian_bootstrap_ci(x,[],2000,.95,42);
[ci,theta,draws]=balanced_bootstrap_ci(x,[],2000,.95,42);

X=[ones(30,1),(1:30)'];
y=X*[1;2]+randn(30,1);
[ci,beta,draws]=wild_bootstrap_ci(X,y,2000,.95,42,'rademacher');

% Animals -> sessions -> trials, all strictly nested:
g={{[1;2;3],[2;3;4]}, {[4;5;6],[5;6;7]}};
stat=@(a)mean(cellfun(@(sessions)mean(cellfun(@mean,sessions)),a));
[ci,theta,draws]=hierarchical_bootstrap_ci(g,stat,2000,.95,42);
```

To run synthetic checks: `addpath('matlab/tests'); smoke_resampling_extensions`.

**Inference cautions:** These are draft methods, not publication-validated implementations. IID and exchangeability assumptions are not interchangeable with time-series dependence. Nested sampling is not appropriate for crossed designs. The Bayesian bootstrap returns posterior credible intervals conditional on the observed support, not automatically frequentist confidence intervals. The wild bootstrap uses fixed-design percentile intervals; verify interval coverage and consider studentization for difficult regression settings. Validate on synthetic known-truth data, examine coverage across repeated datasets, and check estimator-specific behavior before scientific use.

References: Efron (1979); Rubin (1981); Davison, Hinkley & Schechtman (1986); Wu (1986); Liu (1988); Künsch (1989); Politis & Romano (1994); Saravanan, Berman & Sober (2020).

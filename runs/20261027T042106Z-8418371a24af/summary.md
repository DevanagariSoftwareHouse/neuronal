# neuronal run 20261027T042106Z-8418371a24af

- overall: FAIL
- commit: `8418371a24af` on `main`
- origin: actions https://github.com/ze-gois/neuronal/actions/runs/40447187351
- host: Linux 7.2.11-arch1-1 x86_64
- matlab: ~/.local/bin/matlab-r2019a

| suite | status | seconds |
|---|---|---|
| registry | FAIL(2) | 1 |
| rust | pass | 179 |
| python | pass | 82 |
| matlab | FAIL(1) | 148 |
| lean | pass | 452 |

## registry — last 40 lines

```
python3 tools/check_language_boundaries.py
Language boundaries passed: electrophysiology=.m; formal_foundations=.lean
python3 tools/arsenal_registry.py --check
matlab/path/filter_do.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_admit.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_batch_size.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_estimate.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_estimate_filter_do.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_estimate_function.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_estimate_spike_interval_features.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_estimate_spike_interval_plan.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_gpu_sync.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_snapshot.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_storage.m has no \methodentry in 12_method_specifications.tex
matlab/path/resource_wait.m has no \methodentry in 12_method_specifications.tex
matlab/path/spike_interval_features.m has no \methodentry in 12_method_specifications.tex
matlab/path/spike_interval_plan.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_append.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_benchmark.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_binary.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_capabilities.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_close.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_create.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_defaults.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_delete.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_exists.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_flush.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_hdf5.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_hybrid.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_info.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_key.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_list.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_mat.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_path.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_read.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_sqlite.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_validate.m has no \methodentry in 12_method_specifications.tex
matlab/path/storage_write.m has no \methodentry in 12_method_specifications.tex
make: *** [Makefile:8: check] Error 1
make: Leaving directory '~/actions-runner/_work/neuronal/neuronal/books'
```

## matlab — last 40 lines

```
PASS test_filter_do.m

RUN test_filter_family.m
Current IMF  |  #Sift Iter  |  Relative Tol  |  Stop Criterion Hit  
      1      |        1     |   3.2335e-05   |  SiftMaxRelativeTolerance
The decomposition stopped because the current energy ratio is greater than 'MaxEnergyRatio'.
filter family numerical contracts passed
PASS test_filter_family.m

RUN test_filter_probe.m
filter probe tests passed
PASS test_filter_probe.m

RUN test_filter_utilities.m
filter utilities tests passed
PASS test_filter_utilities.m

RUN test_interval_at.m
interval_at lazy interval checks completed
PASS test_interval_at.m

RUN test_interval_families.m
{Error using interval_from_bounds (line 20)
Expected input to be an array with number of columns equal to 2.

Error in interval_renewal (line 20)
nodes = interval_from_bounds(N,fs,[edges(1:end-1),edges(2:end)], 'all');

Error in test_interval_families (line 128)
assert(isempty(interval_renewal(100,10,[], 'all')));

Error in run (line 91)
evalin('caller', strcat(script, ';'));

Error in run_scientific_suite (line 19)
    run(fullfile(neuronal_ci_root,neuronal_ci_name));

Error in run (line 91)
evalin('caller', strcat(script, ';'));
} 
```

# neuronal run 20261025T080935Z-bdf074ecf8bb

- overall: FAIL
- commit: `bdf074ecf8bb` on `main`
- origin: actions https://github.com/ze-gois/neuronal/actions/runs/40175087173
- host: Linux 7.2.11-arch1-1 x86_64
- matlab: ~/.local/bin/matlab-r2019a

| suite | status | seconds |
|---|---|---|
| registry | FAIL(2) | 0 |
| rust | pass | 20 |
| python | pass | 10 |
| matlab | FAIL(1) | 16 |
| lean | pass | 366 |

## registry — last 40 lines

```
$ make -C books check
make: Entering directory '~/actions-runner/_work/neuronal/neuronal/books'
python3 tools/check_sources.py
Validated 87 LaTeX files in two books and 48 mathematical bridges.
python3 tools/check_language_boundaries.py
Language boundaries passed: electrophysiology=.m; formal_foundations=.lean
python3 tools/arsenal_registry.py --check
matlab/path/filter_do.m has no \methodentry in 12_method_specifications.tex
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

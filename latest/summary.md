# neuronal run 20261024T015453Z-09718ec58b1e

- overall: FAIL
- commit: `09718ec58b1e` on `main`
- origin: actions https://github.com/ze-gois/neuronal/actions/runs/40051339792
- host: Linux 7.2.11-arch1-1 x86_64
- matlab: ~/.local/bin/matlab-r2019a

| suite | status | seconds |
|---|---|---|
| registry | pass | 0 |
| rust | pass | 45 |
| python | pass | 20 |
| matlab | FAIL(1) | 30 |
| lean | pass | 581 |

## matlab — last 40 lines

```

RUN test_con2phys_battle_regressions.m
CON2PHYS runtime regression checks passed.
PASS test_con2phys_battle_regressions.m

RUN test_event_alignment.m
event alignment regression checks completed
PASS test_event_alignment.m

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

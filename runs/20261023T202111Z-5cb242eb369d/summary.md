# neuronal run 20261023T202111Z-5cb242eb369d

- overall: FAIL
- commit: `5cb242eb369d` on `main`
- origin: actions https://github.com/ze-gois/neuronal/actions/runs/40017737781
- host: Linux 7.2.9-arch1-1 x86_64
- matlab: ~/.local/bin/matlab-r2019a

| suite | status | seconds |
|---|---|---|
| registry | FAIL(2) | 0 |
| rust | pass | 49 |
| python | pass | 20 |
| matlab | pass | 36 |
| lean | pass | 201 |

## registry — last 40 lines

```
$ make -C books check
make: Entering directory '~/actions-runner/_work/neuronal/neuronal/books'
python3 tools/check_sources.py
Validated 87 LaTeX files in two books and 48 mathematical bridges.
python3 tools/check_language_boundaries.py
Language boundaries passed: electrophysiology=.m; formal_foundations=.lean
python3 tools/arsenal_registry.py --check
matlab/path/assembly_mp_significance.m has no \methodentry in 12_method_specifications.tex
matlab/path/pac_comodulogram.m has no \methodentry in 12_method_specifications.tex
matlab/path/phase_binned_plv.m has no \methodentry in 12_method_specifications.tex
matlab/path/phase_phase_coupling.m has no \methodentry in 12_method_specifications.tex
make: *** [Makefile:8: check] Error 1
make: Leaving directory '~/actions-runner/_work/neuronal/neuronal/books'
```

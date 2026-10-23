# neuronal run 20261023T002501Z-be5f8b681204

- overall: FAIL
- commit: `be5f8b681204` on `main`
- origin: actions https://github.com/ze-gois/neuronal/actions/runs/39877396567
- host: Linux 7.2.9-arch1-1 x86_64
- matlab: ~/.local/bin/matlab-r2019a

| suite | status | seconds |
|---|---|---|
| registry | FAIL(1) | 0 |
| rust | FAIL(101) | 4 |
| python | pass | 13 |
| matlab | pass | 17 |
| lean | pass | 205 |

## registry — last 40 lines

```
$ make -C books check
make: Entering directory '~/actions-runner/_work/neuronal/neuronal/books'
python3 tools/check_sources.py
Validated 86 LaTeX files in two books and 48 mathematical bridges.
python3 tools/check_language_boundaries.py
Language boundaries passed: electrophysiology=.m; formal_foundations=.lean
python3 tools/arsenal_registry.py --check
Arsenal registry consistent: 139 methods, 55 ARS theorems.
make: Leaving directory '~/actions-runner/_work/neuronal/neuronal/books'
$ git diff --check b495f5984a57a34839f06c12631b47d12d4bff0b HEAD
```

## rust — last 40 lines

```
$ cargo --version
cargo 1.99.0-nightly (7c83d4cc0 2026-07-29)
$ cargo fmt --all -- --check
$ cargo build --workspace --locked
    Updating crates.io index
error: cannot update the lock file ~/actions-runner/_work/neuronal/neuronal/Cargo.lock because --locked was passed to prevent this
help: to generate the lock file without accessing the network, remove the --locked flag and use --offline instead.
```

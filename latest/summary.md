# neuronal run 20261023T003716Z-13abbb9eb35e

- overall: FAIL
- commit: `13abbb9eb35e` on `main`
- origin: actions https://github.com/ze-gois/neuronal/actions/runs/39878528037
- host: Linux 7.2.9-arch1-1 x86_64
- matlab: ~/.local/bin/matlab-r2019a

| suite | status | seconds |
|---|---|---|
| registry | pass | 0 |
| rust | FAIL(101) | 132 |
| python | pass | 23 |
| matlab | pass | 27 |
| lean | pass | 389 |

## rust — last 40 lines

```
$ cargo --version
cargo 1.99.0-nightly (7c83d4cc0 2026-07-29)
$ cargo fmt --all -- --check
$ cargo build --workspace --locked
    Updating crates.io index
warning: spurious network error (3 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (3 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (3 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (3 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (3 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (2 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (2 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (2 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (2 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (2 tries remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (1 try remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (1 try remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (1 try remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (1 try remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
warning: spurious network error (1 try remaining): transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
error: failed to get `thiserror` as a dependency of package `neuronal-core v0.1.0 (~/actions-runner/_work/neuronal/neuronal/crates/neuronal-core)`

Caused by:
  failed to load source for dependency `thiserror`

Caused by:
  unable to update registry `crates-io`

Caused by:
  download of th/is/thiserror failed

Caused by:
  transfer too slow: failed to transfer more than 10 bytes in 30s (transferred 0 bytes)
```

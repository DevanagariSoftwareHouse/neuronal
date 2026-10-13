# Dell G15 as the default neuronal GitHub Actions runner

All six required jobs use `runs-on: [self-hosted, linux, x64, dell-g15]`. They run on **one** Dell G15 runner, including real MATLAB and pinned Lean/Mathlib. This replaces GitHub-hosted Ubuntu runners only after the self-hosted machine is configured. Jobs will remain queued indefinitely while a compatible runner is offline.

## Register and protect the runner

1. In `ze-gois/neuronal` open **Settings → Actions → Runners → New self-hosted runner** and select Linux x64.
2. Follow GitHub's currently displayed installation and registration instructions on the Dell G15. GitHub provides a short-lived, sensitive registration token; do not save that token in Git, issue comments or build logs.
3. Give the runner the custom label **`dell-g15`** (alongside the default `self-hosted`, `linux`, `x64` labels). Verify it is **Online / Idle** in repository Settings.
4. Use a dedicated, unprivileged service account with limited host access. Run the service under that account, not root. Keep its HOME, PATH and software licensing available in noninteractive sessions. Do not mount personal SSH keys, browser profiles or privileged Docker sockets into CI.
5. On a public repo, self-hosted runner execution of untrusted fork PRs is dangerous. These workflows skip fork-origin PR jobs; configure repository policy to reject untrusted fork workflow execution and do not waive required checks. Fork contributions should be vetted before re-submission from a trusted repository branch, preferably using a separate isolated GitHub-hosted review workflow.
6. Use one job at a time for this single machine; jobs from concurrent workflow runs will queue normally. Keep sufficient disk space for Mathlib, TeX and Rust build outputs.

## Host provisioning (Arch Linux)

Provision system dependencies manually, **outside** workflow execution:

- `git`, `bash`, `make`, `python`, Python `venv`/`pip`, `curl`, `gcc`, build libraries and certificates.
- Rust through `rustup`, with the project's required toolchain, `cargo`, `rustfmt`, `clippy`.
- TeX Live packages providing `pdflatex`, `bibtex` and all packages/fonts referenced by both manuscripts. `make -C books all` should succeed as the runner user.
- MATLAB R2019a Update 9 available as the executable `matlab-r2019a` in the runner user's PATH, with a functioning noninteractive license and the **Signal Processing Toolbox**. The workflow intentionally does not download/install or activate a new MATLAB release on each run. Confirm the installed release and toolbox are compatible with the scientific suite. The former hosted job used R2024b; the Dell currently has R2019a Update 9, so the scientific suite must pass on R2019a before merge. The launcher changes the process working directory; CI supplies the absolute checked-out script path.
- Lean 4 via `elan` for the **same runner account**: `$HOME/.elan/bin/lean` and `$HOME/.elan/bin/lake` must exist. The repository pins `leanprover/lean4:v4.34.0`; from `books/formal_foundations/lean`, execute `lake --version`, `lake exe cache get`, `lake build`.

## Preflight on the runner account

```bash
git --version
python3 --version
cargo --version
rustc --version
pdflatex --version
bibtex --version
test -x "$HOME/.elan/bin/lake"
cd books/formal_foundations/lean && "$HOME/.elan/bin/lake" --version
cd ../../..
matlab-r2019a -batch "assert(license('test','Signal_Toolbox')); ver"
```

The commands assume you are in the root of a `neuronal` checkout when entering the Lean directory. Run them as the same dedicated user that runs the GitHub Actions service.

## CI cutover and acceptance

Keep this branch as a PR until the Dell runner is verified Online with the labels above and **all six jobs** pass for the same PR head SHA:

1. Build neuronal books.
2. Formal Lean (including kernel and graph checks).
3. MATLAB Scientific Tests using locally installed MATLAB and Signal Processing Toolbox.
4. Arsenal Registry and Diff Integrity.
5. Rust Build Clippy and Tests.
6. Python Package and Integration Tests.

Once green, merge the PR and confirm a successful run on `main`. Branch protection rules must also require the six job names; workflow YAML alone cannot enforce that policy. Do not merge merely because all jobs are queued or skipped.

## Reversal

If runner availability or licensing is unreliable, revert the workflow-change commits through a PR, restoring hosted Ubuntu jobs. Preserve the prior successful CI run evidence and do not force-push `main`.

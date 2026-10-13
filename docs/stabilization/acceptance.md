# Integration acceptance and recovery

PR #2 is the sole integration vehicle. No merge while a required result is
missing, skipped, cancelled or failing. Recheck the candidate head and the
base before merging; a passing run for an earlier head is insufficient.

Required job names:

- `books` (Build neuronal books)
- `lean` (Formal Lean; includes kernel and dependency graph checks)
- `MATLAB Scientific Tests` (real R2024b plus Signal Processing Toolbox)
- `Arsenal Registry and Diff Integrity`
- `Rust Build Clippy and Tests`
- `Python Package and Integration Tests`

Record run URLs, candidate SHA, runtime versions and toolbox listing. MATLAB
writes `matlab/build/scientific-tests.log`, uploaded as CI evidence. CI uses the
committed Lean toolchain and manifest. No MATLAB or Lean runtime is available
in the editing container; local source checks cannot satisfy those gates.

## Evidence meanings

- **Documented:** a function has a specification and valid registry links.
- **Proved in text / cited:** the status of the English mathematical argument.
- **Numerically tested:** only the contracts actually exercised by a passing
  scientific suite on the recorded commit. Not all 88 methods are exhaustively
  validated by the suite, and passing tests do not prove physiological claims.
- **Lean verified:** only declarations actually checked by the kernel; historical
  registry evidence is not evidence of a current CI run. ARS `lean: null` entries
  must never be counted as formal proofs.

## Repository settings

Require the six jobs above for main; require the branch to be up to date and
prevent force pushes. Workflow files do not configure branch protection.
If the available GitHub connection cannot administer these rules, report that
explicitly as an outstanding settings action. Manually verify all six checks
for this integration; do not claim repository-wide enforcement was configured.
Do not use auto-merge to substitute for checking absent required jobs.

## Recovery

Baseline SHAs are in `baseline.json`; retain source branches until post-merge
validation. Corrections are additive commits. Revert an offending stabilization
commit on the integration branch, resolve dependent reverts explicitly, then
rerun all gates. Do not reset or force-push main.

For a validated ordinary two-parent merge that subsequently regresses, create
`revert/neuronal-stabilization` from current main and run
`git revert -m 1 <actual-merge-sha>`. Validate the revert PR before merging.
After any successful merge run all six jobs against the actual main commit.
Only then retire obsolete branches and consider the paired paper_con2phys PR #16.

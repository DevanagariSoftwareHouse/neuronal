# Arsenal feature reconciliation — 2026-10-12

## Source and destination

- Source: `feat/arsenal-into-books` at `939ad037e8dacdb93240283919fa6bc1be9ada51`.
- Already integrated feature work: `151e78fb627d470d7278ae5d35a212ce880b5bd5` on the migration branch.
- Destination baseline: `main` at `19592df3b30689fe0615485f60461023003281d9`, after PR #2.
- Integration mode: explicit reconciliation of the original feature commit into the Git ancestry, retaining the destination tree. This is not a textual reapplication of the older commit.

## Why a textual cherry-pick would be wrong

The source feature commit adds the method-specification chapter, arsenal proof chapters, generated theorem registry, registry checker and MATLAB identity suite. The substantive feature work was already copied into PR #2, and downstream commits corrected numerical and formal contracts. A raw cherry-pick would conflict with or roll back those later corrections.

Compare both sides using `git diff main...feat/arsenal-into-books` and `git log --graph --oneline --all`; the three-dot comparison includes changes already transferred independently. Compare file content against the integrated commit and subsequent fixes instead of treating that diff as unmerged functionality.

## Preserved implementation

- `books/electrophysiology/chapters/12_method_specifications.tex`.
- `books/formal_foundations/chapters/10_arsenal/` and book links.
- `books/shared/theorems.yml` and `books/tools/arsenal_registry.py`.
- `matlab/tests/check_arsenal_identities.m` and later numerical corrections.
- All post-import Lean, MATLAB and scientific corrections from PR #2.

The reconciliation commit deliberately preserves the exact `main` code tree except for this audit document. The original feature commit is recorded as an additional Git parent, so the branch history is integrated without downgrading corrected code.

## Acceptance and evidence

Require these workflows on the PR head: `Build neuronal books`, `Formal Lean`, `Scientific and package validation` (real MATLAB R2024b, registry, Rust, Python). Merge only when all pass. This historical reconciliation is not new proof of scientific correctness; refer to `docs/stabilization/acceptance.md` for the existing validation scope.

## Rollback

Revert the documentation change if needed. The original feature branch remains intact until post-merge ancestry and CI are verified.

# Source branch review — 12 October 2026

All 17 remote branches were compared against source main and the neuronal migration.
A commit outside main ancestry does not imply missing code: several branches were squash-merged or refactored.
Decisions below use current source files as well as merge-base diffs.

| Branch | Tip | Decision |
|---|---|---|
| `analysis/q01-q15` | `76f7300` | Already integrated in source main. Import five data-independent helpers; dataset preparation, questionnaire and inference policies remain in paper_con2phys. |
| `b01-lfp-spectrogram` | `44504ce` | Legacy dataset-bound script; current implementation is extracted into source path/view_lfp_spectrogram.m. Retain in paper_con2phys. |
| `b02-b04-lfp-inspections` | `968a229` | Legacy dataset-bound views; current source main has extracted view_lfp_wavelet/spatial/quality. Retain in paper_con2phys. |
| `c00-spectral-peaks` | `ebeb2d3` | Dataset-bound inspection script, superseded by main wrappers and spectral_peaks/electrode_peaks. Reusable spectral primitives already imported. |
| `d00-frequency-pool` | `727d8fc` | Dataset-bound pipeline with output-directory and recording metadata contracts; retain in source. Reusable filtering primitives already imported. |
| `docs/theorems-mathematical-foundations` | `a72614c` | Merged into source main and superseded by the imported expanded manuscript branch. No missing editorial source. |
| `draft/arsenal-methods` | `38b0962` | Imported via main, including Path-to-path normalization and spike_counts_edges integration; do not regress to old Path versions. |
| `feat/lean-formal-inventory-pilot` | `97e1375` | Latest source 97e1375 already imported, including all.bib, proofs and manuscript expansions. Exclude generated .lake files; retain new editorial layout. |
| `feature/lfp-envelope-sliding-moments` | `0e9a668` | Function and test exactly match main. Import both into matlab/; preserve full algorithm and test content. |
| `fix/arsenal-smoke-regressions` | `b4f7463` | Import all eight changed files, adapting arsenal/ to matlab/. Includes four corrected functions, three regression scripts and review notes. |
| `lfp-window-inspector` | `3edea5d` | Dataset-bound interactive script; source main already contains extracted view_lfp_raw and caller. Retain source integration. |
| `main` | `7d5a437` | Authoritative source for standalone envelope moments and reusable analysis helpers. Keep dataset loaders/configuration and GUI adapters in source. |
| `migration/books-to-neuronal` | `daaf924` | Companion PR #16; its deletions implement source retirement and must not be applied to neuronal. |
| `refactor/project-path` | `af2a606` | Merged source layout; migrate reusable helpers using lower-case matlab/path. Dataset adapters stay in source. |
| `refactor/two-books-layout` | `c660156` | Merged source layout; superseded by neuronal book-specific Lean/audit organization. |
| `revert-7-revision/q00-q15-references` | `d275fe1` | Reversion is already in main ancestry. Do not resurrect reverted questionnaire behavior. |
| `revision/q00-q15-references` | `e1335e0` | Questionnaire revision was explicitly reverted. Teaching-source note and alternative estimators are retained in source history, not reinstated as current behavior. |

## Additional reusable functions

Six functions imported from source main: `lfp_envelope_moments`, `decode_trials`,
`decoded_mi`, `greedy_modularity`, `spike_bins`, and `trial_features`.
`participation` is not duplicated: `participation_ratio` already implements the same
covariance dimensionality estimand with its own documented input contract.
Dataset loaders, `trial_times`, waveform classification by questionnaire configuration,
summaries and three-area viewers remain with their CON²PHYS callers.

The source main keeps its helper copies for compatibility; this PR imports them
without changing paper_con2phys caller behavior. Future fixes should be coordinated
until those callers are migrated. The new neuronal methods are exploratory.

## Validation

Imported envelope regression script and added synthetic contracts for the five helpers.
MATLAB is unavailable: none of these MATLAB tests is claimed as executed here.
Reviewed function signatures, internal dependencies, provenance hashes and migration paths.
The previous five English/Lean correspondence fingerprint failures remain outside this branch consolidation.

Machine-readable branch tips, changed-file inventories and import hashes:
[BRANCH_REVIEW_2026_10_12.json](BRANCH_REVIEW_2026_10_12.json).

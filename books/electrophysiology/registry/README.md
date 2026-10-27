# Electrophysiology book / MATLAB registry

Source: `ze-gois/neuronal` `main` snapshot, 2026-10-27 (previous audit at `8418371`). This is an **editorial inventory and migration plan**, not evidence that the revised chapters have been typeset, tested, or scientifically validated.

## Files

- [functions.json](functions.json): all **262** public MATLAB functions (following removal of an experimental third-party filter). Includes **50** proposed chapters and **six** appendices.
- `primary_chapter`: where the mathematics or implementation is introduced in the narrative.
- `secondary_chapters`: additional relevant chapters, not additional definitions of the method.
- `source_tex` / `existing_tex`: source files supplying existing derivations, discussions and exercises.
- `alias_of` + `placement: appendix_only`: an old compatibility entry point with no independent chapter allocation. The wrappers remain available for backwards compatibility.
- `source_disposition`: explicit decisions for original manuscript material not corresponding to a narrative chapter.

### Compatibility wrappers

| Alias | Canonical function | Placement |
|---|---|---|
| `spike_triggered_average` | `event_triggered_average` | Appendix B only |
| `event_aligned_raster` | `event_aligned_segments` | Appendix B only |
| `spike_raster_sparse` | `sparse_count_matrix` | Appendix B only |
| `plot_event_raster` | `plot_event_aligned` | Appendix B only |

Some aliases preserve output metadata or default transformations; `alias_of` identifies the preferred general API, **not** a guarantee of identical signatures.

### Reconciliation of original sources

| Original LaTeX file | Editorial destination | Done? |
|---|---|---|
| `00_guide.tex` | Book front matter | Already there; retained |
| `01_logic_sets.tex` | Formal Foundations, logic and sets; Appendix A pointer | Proposed, not moved |
| `02_analysis.tex` | Formal Foundations, analysis; Appendix A pointer | Proposed, not moved |
| `03_linear_algebra.tex` | Formal Foundations, linear algebra; Appendix A pointer | Proposed, not moved |
| `12_method_specifications.tex` | Appendix B: function reference | Proposed, not moved |

Appendices A–F are restored in `functions.json`; the current compiled `main.tex` is intentionally **not** rewritten in this PR. Current `ARS-*` theorem identifiers and the existing exercises must survive later migration.

### Source licensing

Experimental third-party filtering code was removed from the public MATLAB path rather than bundled under this MIT repository. The main toolbox's native filter design and application functions remain available.

### Existing and missing computational material

- C42 is supported by test and identity-check scripts in `matlab/tests/` including `check_arsenal_identities.m`, `check_biophysical_derivations.m` and `run_scientific_suite.m`. These are not public method functions.
- C14–C15 have substantial existing theory but no mapped MATLAB simulation functions. Rust generators for Ornstein–Uhlenbeck, stochastic LIF, Hopf and Kuramoto processes are **proposals**, not existing implementations.
- C49 references existing CON²PHYS questionnaire helpers currently in `matlab/path`. Their relocation to `analysis/+con2phys` is **proposed**, not performed.
- `Contents.m` is reported to omit **68** remaining public methods; the index is not an authoritative inventory until regenerated and reconciled.
- Strong max-T FWER claims require conditions such as **subset pivotality**, not exchangeability alone.

## Next pilot

See [Part II migration plan](../PART_II_MIGRATION.md). The steps are intentionally incremental and leave all nine other Parts untouched until the filter/spectral pilot has a successful LaTeX build and relevant MATLAB test results.

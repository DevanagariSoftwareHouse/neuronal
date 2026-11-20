# Part II pilot — chapter migration without theorem loss

**Scope:** proposed C05–C09 (filters, spatial preprocessing, spectral estimation, time–frequency representations, and adaptive decomposition). This document commits to a migration procedure; it does not claim a new book layout has already compiled.

## Preserved sources

- `05a_filtering_sampling.tex`: filtering, aliasing, stability, state, causality and FIR/IIR proofs.
- `05_harmonic_analysis.tex`: Fourier/spectral derivations, auto-regression and Wiener–Hopf.
- `05c_wavelets_spectral_inference.tex`: time–frequency and wavelet mathematics, multitaper, coherence and phase.
- `05b_biophysics_inverse.tex`: rereferencing, spatial interpretation and the forward model.
- Existing exercises, `08_foundational_nine.tex`, `09_proofs.tex`, `10_arsenal_crosswalk.tex`, and all `ARS-*` references remain intact during the pilot.

## Incremental acceptance sequence

1. Freeze the source revision, inventory all theorem and `\\label` identifiers reachable from the current `main.tex`, and record an integrated PDF build baseline.
2. Introduce the Part II subsection/chapter wrappers **without deleting or renaming** any theorem labels. Preserve the existing source text in the first pass.
3. Move one source family at a time (C05 then C06–C09), keeping old references valid. Resolve collisions before changing the next family.
4. Run the repository's `test_filter_*`, `test_wavelet_filter_bank`, and `test_spectral_*` test scripts using a compatible MATLAB runtime. Run `check_arsenal_identities` and `run_scientific_suite` where dependencies permit.
5. Compile the integrated LaTeX book with the repository's supported build target, repeat compilation to settle cross-references, and check unresolved references, duplicate labels and changed theorem identifiers.
6. Only after the Part II pilot passes, extend the migration to remaining Parts. Treat Appendix A / Formal Foundations moves as separately validated source migrations.

## Future appendix contract

- **A:** mathematical prerequisite pointers to Formal Foundations, not a duplicate textbook.
- **B:** `12_method_specifications.tex`, authoritative MATLAB function reference and alias index.
- **C:** verified theorems and numerical invariants, including `09_proofs.tex` links.
- **D:** controlled simulations and counterexamples; planned Rust dynamical-model generators.
- **E:** hardware, MATLAB/Rust environments and reproducibility.
- **F:** notation and glossary.

## Exclusions

No one-shot rewrite of `main.tex`, no attempt to migrate all Parts, no unverified claims of mathematical equivalence across distinct filtering APIs, no claim that Rust models already exist, and no automatic movement of CON²PHYS-specific helpers in this PR.

# MATLAB book figures

Two deterministic synthetic figures for the electrophysiology book:
an idealized finite line-current forward model and an infinite passive
cable's frequency response. These illustrate mathematical models, not
empirical recordings. See Einevoll et al. 2013 (DOI 10.1038/nrn3599).

Layout:
- build_book_figures.m generates figures and JSON/TSV build manifests.
- generators/ holds one generator per figure; helpers/ styles and exports.
- manifests/figures.tsv is the versioned draft/review/final registry.
- ../tests/smoke_book_figures.m runs numerical and file-artifact checks.
- ../build/figures/ contains ignored EPS/PDF/JSON/TSV outputs.

From the repository root, use MATLAB:

    addpath(fullfile(pwd, 'matlab', 'figures'));
    manifest = build_book_figures();
    run('matlab/tests/smoke_book_figures.m');

A preview including both figures in the book can be built with:

    make -C books/electrophysiology figures-preview pdf

The Makefile uses matlab-r2019a by default to match the Dell CI runner;
override the MATLAB variable if your executable has another name.

Figures remain drafts until the smoke test runs in the real MATLAB
runtime and vector exports have been inspected. The regular LaTeX build
does not require MATLAB; chapter inclusions use IfFileExists.
Only EPS/PDF previews are copied, and generated outputs are Git-ignored.
Use explicit approval before packaging generated PDFs in a release.

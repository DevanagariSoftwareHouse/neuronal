# Generated figure integration

The existing book builds with pdflatex and includes generated PDF assets.
The MATLAB generator also saves EPS vector artwork.

From the repository root:

    make -C books/electrophysiology figures-preview pdf

The figures-preview target executes matlab-r2019a -batch, produces
matlab/build/figures/{EPS,PDF,manifest.json,manifest.tsv} and copies PDF
previews into books/electrophysiology/figures/generated/. Both figures
are conditionally included in the relevant sections of chapter
05b_biophysics_inverse.tex when the files are present.

Ordinary builds remain MATLAB-independent:

    make -C books/electrophysiology pdf

To verify numerics and generated artifacts manually in MATLAB:

    run('matlab/tests/smoke_book_figures.m');

The scientific suite already discovers script-form tests in matlab/tests,
so this smoke test participates in the existing self-hosted MATLAB CI
without modifying the suite runner.

The versioned registry is matlab/figures/manifests/figures.tsv. All pilot
figures are draft. PDF previews are Git-ignored and are not
publication-approved by virtue of a successful preview build. Promote
only after checking numerical and graphical results. Explicitly package
reviewed figures for publication, or regenerate with MATLAB before
building a releasable book.

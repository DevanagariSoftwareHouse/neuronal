# MATLAB educational examples

Put executable textbook examples, synthetic datasets, figures, and regression/smoke tests here, referencing functions under `matlab/path/` (relative to neuronal root). Keep research questionnaire scripts in their existing locations.

This directory is a placeholder for the next stage; no new MATLAB computations have been implemented by the repository reorganization.

## Second-order modulation study

`second_order_modulation_study.m` regenerates every number in the book
chapter on second-order amplitude and phase modulation: recovery at the
default parameters, calibration of the slow-phase shift null, and the four
confound experiments. It writes a LaTeX results file and a figure to
`matlab/build/second_order_modulation/` and copies them into
`books/electrophysiology/figures/generated/` (Git-ignored), where the
chapter picks them up instead of its fallback table. From the repository
root:

    addpath(fullfile(pwd,'examples','matlab'));
    study = second_order_modulation_study();          % chapter defaults
    study = second_order_modulation_study('Quick',true);  % smoke run

Requires the Signal Processing Toolbox. `matlab/tests/smoke_second_order_study.m`
runs the quick mode in CI.

%% Smoke test: examples/matlab/second_order_modulation_study.m in quick mode.
% Checks that every experiment runs and the outputs are written; the quick
% numbers are not used by the book. Requires Signal Processing Toolbox.
neuronal_som_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
neuronal_som_old_path = path;
neuronal_som_path_cleanup = onCleanup(@() path(neuronal_som_old_path));
addpath(fullfile(neuronal_som_root,'examples','matlab'));
neuronal_som_out = tempname;
neuronal_som_out_cleanup = onCleanup(@() rmdir(neuronal_som_out,'s'));
neuronal_som = second_order_modulation_study('Quick',true,'OutputDir',neuronal_som_out);
assert(exist(fullfile(neuronal_som_out,'second_order_results.tex'),'file')==2);
assert(exist(fullfile(neuronal_som_out,'second_order_study.mat'),'file')==2);
neuronal_som_pdf = dir(fullfile(neuronal_som_out,'fig_second_order_recovery.pdf'));
assert(~isempty(neuronal_som_pdf) && neuronal_som_pdf.bytes > 100);
assert(isequal(size(neuronal_som.A.values),[2 9]) && all(isfinite(neuronal_som.A.values(:))));
assert(all(isfinite([neuronal_som.F.ratio_mean neuronal_som.F.phase_mean])));
% The analytic prediction for the instantaneous-frequency confound.
assert(abs(neuronal_som.F.prediction_ratio-0.6153)<1e-3);
assert(abs(neuronal_som.F.prediction_phase+0.6121)<1e-3);
fprintf('smoke_second_order_study: outputs written in %.1f s\n', ...
    neuronal_som.elapsed_seconds);

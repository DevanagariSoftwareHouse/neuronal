%% Smoke test for deterministic scientific book figures (run by scientific suite).
% Compatible with the script-only MATLAB scientific test runner.
neuronal_fig_matlab_dir = fileparts(fileparts(mfilename('fullpath')));
neuronal_fig_figures_dir = fullfile(neuronal_fig_matlab_dir, 'figures');
neuronal_fig_old_path = path;
neuronal_fig_path_cleanup = onCleanup(@() path(neuronal_fig_old_path));
addpath(neuronal_fig_figures_dir);

neuronal_fig_test_output = tempname;
mkdir(neuronal_fig_test_output);
neuronal_fig_test_cleanup = onCleanup(@() rmdir(neuronal_fig_test_output, 's'));

neuronal_fig_manifest = build_book_figures(neuronal_fig_test_output);
assert(numel(neuronal_fig_manifest) == 2, 'Expected exactly two pilot figures.');
for neuronal_fig_k = 1:numel(neuronal_fig_manifest)
    neuronal_fig_eps = dir(neuronal_fig_manifest(neuronal_fig_k).eps_path);
    neuronal_fig_pdf = dir(neuronal_fig_manifest(neuronal_fig_k).pdf_path);
    assert(~isempty(neuronal_fig_eps) && neuronal_fig_eps.bytes > 100, 'Empty EPS.');
    assert(~isempty(neuronal_fig_pdf) && neuronal_fig_pdf.bytes > 100, 'Empty PDF.');
    assert(strcmp(neuronal_fig_manifest(neuronal_fig_k).status, 'draft'));
end
neuronal_fig_loaded = jsondecode(fileread(fullfile(neuronal_fig_test_output,'manifest.json')));
assert(numel(neuronal_fig_loaded) == 2, 'Incorrect JSON manifest record count.');
assert(exist(fullfile(neuronal_fig_test_output,'manifest.tsv'), 'file') == 2);

% Independent numerical integral versus exact line-source Green kernel.
neuronal_fig_z1 = -200e-6;
neuronal_fig_z2 = 200e-6;
neuronal_fig_rho = 80e-6;
neuronal_fig_ze = 73e-6;
neuronal_fig_analytic = asinh((neuronal_fig_z2-neuronal_fig_ze)/neuronal_fig_rho) ...
    - asinh((neuronal_fig_z1-neuronal_fig_ze)/neuronal_fig_rho);
neuronal_fig_numeric = integral(@(z) 1./sqrt(neuronal_fig_rho^2 ...
    + (z-neuronal_fig_ze).^2), neuronal_fig_z1, neuronal_fig_z2);
assert(abs(neuronal_fig_analytic-neuronal_fig_numeric) < 1e-9);

% The normalized infinite-cable transfer is smaller at larger distances.
neuronal_fig_w = real(sqrt(1+1i*2*pi*100*15e-3));
assert(neuronal_fig_w > 1);
assert(exp(-2*(neuronal_fig_w-1)) < exp(-0.5*(neuronal_fig_w-1)));

clear neuronal_fig_test_cleanup neuronal_fig_path_cleanup;
fprintf('smoke_book_figures: PASS\n');

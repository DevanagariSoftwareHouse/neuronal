%% Run every scientific regression script with a real MATLAB runtime.
% From repository root: run('matlab/tests/run_scientific_suite.m')
assert(~exist('OCTAVE_VERSION','builtin'),'A real MATLAB runtime is required.');
assert(license('test','Signal_Toolbox') == 1,'Signal Processing Toolbox is required.');
neuronal_ci_root=fileparts(mfilename('fullpath'));
neuronal_ci_output=fullfile(neuronal_ci_root,'..','build');
if ~exist(neuronal_ci_output,'dir'), mkdir(neuronal_ci_output); end
diary(fullfile(neuronal_ci_output,'scientific-tests.log'));
neuronal_ci_diary=onCleanup(@() diary('off'));
fprintf('MATLAB %s\nCommit under test: %s\n',version,getenv('GITHUB_SHA'));
ver
neuronal_ci_files=dir(fullfile(neuronal_ci_root,'*.m'));
neuronal_ci_count=0;
for neuronal_ci_index=1:numel(neuronal_ci_files)
    neuronal_ci_name=neuronal_ci_files(neuronal_ci_index).name;
    if strcmp(neuronal_ci_name,'run_scientific_suite.m'), continue; end
    fprintf('\nRUN %s\n',neuronal_ci_name);
    rng(0,'twister'); % Reset state before each independent script.
    run(fullfile(neuronal_ci_root,neuronal_ci_name));
    neuronal_ci_count=neuronal_ci_count+1;
    fprintf('PASS %s\n',neuronal_ci_name);
end
assert(neuronal_ci_count>=8,'Scientific suite unexpectedly incomplete.');
fprintf('\nPASS: %d scientific scripts\n',neuronal_ci_count);
diary off

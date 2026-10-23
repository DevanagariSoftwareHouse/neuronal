%% Configure analysis paths without clearing caller data or changing directory.
clc; clear all
neuronal_path = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(neuronal_path,'matlab','neuronal_startup.m'));
addpath(fullfile(neuronal_path,'analysis'));


matlab_dir = '/home/gois/Insync/jhenriquetdg@gmail.com/Google Drive/matlab/';
run(fullfile(matlab_dir,'startup.m'))

matlab_dir = '/home/gois/Insync/jhenriquetdg@gmail.com/Google Drive/matlab/';
run(fullfile(matlab_dir,'neuronal/startup.m'))

%%
catalog = neuronal_catalog()
data    = catalog.data

%%

run('analysis/a00_startup.m')

qcfg = struct();

% Resampling
qcfg.seed                = 42;
qcfg.bootstrap           = 2000;
qcfg.minimum_finite_rows = 3;
qcfg.inference = struct( ...
    'method', 'auto', ...
    'level',  0.95);

% Analysis settings
qcfg.block_seconds   = 30;
qcfg.matched_units   = 5;
qcfg.minimum_spikes  = 50;
qcfg.null_replicates = 100;

% Waveform classification — verify sampling rate from acquisition metadata.
qcfg.waveform_srate = 30000;
qcfg.narrow_ms      = 0.4;

% Reference LFP channel within each area: [area1 area2 area3].
qcfg.lfp_channels = [1 1 1];

% Do not assume independence between clusters from different areas.
qcfg.independent_groups = false;

% Optional overrides for individual questions.
qcfg.questions = struct();
qcfg.questions.q02 = struct( ...
    'method',       'stationary', ...
    'block_length', 4);  % Four 30-second summaries, not four samples.
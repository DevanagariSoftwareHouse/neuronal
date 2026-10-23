%% Configure paths only; ingestion is explicit: run('digest/ingest_con2phys.m').
clc
clear

matlab_dir = '/home/gois/Insync/jhenriquetdg@gmail.com/Google Drive/matlab/';
neuronal_dir = fullfile(matlab_dir,'neuronal');
addpath(fullfile(neuronal_dir,'matlab','path'))
addpath(fullfile(neuronal_dir,'analysis'))

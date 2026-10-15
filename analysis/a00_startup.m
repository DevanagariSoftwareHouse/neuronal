%% Configure analysis paths without clearing caller data or changing directory.
neuronal_path = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(neuronal_path,'matlab','neuronal_startup.m'));
addpath(fullfile(neuronal_path,'analysis'));

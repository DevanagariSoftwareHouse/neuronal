%% Hierarchical bootstrap: animals -> trials, unequal trial counts
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(104,'twister');
nAnimals=18; mu=4; animal_sd=1.5; trial_sd=.6;
groups=cell(nAnimals,1);
for a=1:nAnimals
    nTrials=20+mod(a,9);
    animal_effect=animal_sd*randn;
    groups{a}=mu+animal_effect+trial_sd*randn(nTrials,1);
end
statfun=@(g)mean(cellfun(@mean,g)); % animals equally weighted
[ci,theta,draws]=hierarchical_bootstrap_ci(groups,statfun,3000,.95,104);
fprintf('Hierarchical bootstrap: true grand mean %.3f, estimate %.3f, CI [%.3f, %.3f]\n',mu,theta,ci(1),ci(2));
figure('Name','Hierarchical bootstrap');
histogram(draws,35); hold on;
xline(mu,'r--','Population mean'); xline(theta,'k-','Observed mean');
xline(ci(1),'b:','Lower'); xline(ci(2),'b:','Upper');
xlabel('Animal-weighted mean'); ylabel('Replicates');
title('Resampling animals, then trials within animals');
% Independent biological replicates are animals, not individual trials.

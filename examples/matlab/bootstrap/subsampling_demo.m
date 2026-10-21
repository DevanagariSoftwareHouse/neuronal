%% Subsampling without replacement: confidence interval for IID mean
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(106,'twister');
mu=2; n=400; x=mu+randn(n,1); m=40; B=2000;
[ci,theta,draws]=subsampling_ci(x,@mean,m,B,.95);
fprintf('Subsampling: true mean %.3f, estimate %.3f, CI [%.3f, %.3f]\n',mu,theta,ci(1),ci(2));
figure('Name','Subsampling');
histogram(draws,35); hold on;
xline(mu,'r--','True mean'); xline(theta,'k-','Full sample mean');
xlabel('Subsample mean'); ylabel('Replicates');
title('Subsampling without replacement (m < n)');
% CI is derived from scaled estimator differences, not raw draw quantiles.

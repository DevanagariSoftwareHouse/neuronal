%% Balanced bootstrap: percentile confidence interval of a mean
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(102,'twister');
mu=5; n=60; x=mu+randn(n,1);
[ci,theta,draws]=balanced_bootstrap_ci(x,[],3000,.95,102);
fprintf('Balanced bootstrap: true mean %.3f, estimate %.3f, CI [%.3f, %.3f]\n',mu,theta,ci(1),ci(2));
% Balanced replicates ensure every observation occurs B times globally.
assert(abs(mean(draws)-theta)<1e-10);
figure('Name','Balanced bootstrap','WindowStyle','docked');
histogram(draws,35); hold on;
xline(mu,'r--','True mean'); xline(theta,'k-','Observed mean');
xline(ci(1),'b:','Lower'); xline(ci(2),'b:','Upper');
xlabel('Resampled mean'); ylabel('Replicates'); title('Balanced bootstrap');

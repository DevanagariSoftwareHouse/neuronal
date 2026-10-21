%% Bayesian bootstrap: posterior uncertainty of the population mean
% Synthetic independent Gaussian observations with known true mean.
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(101,'twister');
mu=3; sigma=2; n=50; x=mu+sigma*randn(n,1);
[ci,theta,draws,weights]=bayesian_bootstrap_ci(x,[],3000,.95,101);
fprintf('Bayesian bootstrap: true mean %.3f, estimate %.3f, credible interval [%.3f, %.3f]\n',mu,theta,ci(1),ci(2));
assert(all(abs(sum(weights,1)-1)<1e-10));
figure('Name','Bayesian bootstrap');
histogram(draws,35); hold on;
xline(mu,'r--','True mean'); xline(theta,'k-','Observed mean');
xline(ci(1),'b:','Lower'); xline(ci(2),'b:','Upper');
xlabel('Weighted sample mean'); ylabel('Draws'); title('Dirichlet-weight Bayesian bootstrap');
% This is a posterior credible interval, not automatically a frequentist CI.

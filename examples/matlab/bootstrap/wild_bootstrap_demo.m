%% Wild bootstrap: OLS with heteroskedastic errors
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(103,'twister');
n=100; t=linspace(-1,1,n)'; X=[ones(n,1),t];
beta_true=[1.5;2.0];
noise_sd=.25+1.2*abs(t);
y=X*beta_true+noise_sd.*randn(n,1);
[ci,beta,draws]=wild_bootstrap_ci(X,y,3000,.95,103,'rademacher');
fprintf('Wild bootstrap: slope truth %.3f, estimate %.3f, CI [%.3f, %.3f]\n',beta_true(2),beta(2),ci(1,2),ci(2,2));
figure('Name','Wild bootstrap');
subplot(1,2,1); scatter(t,y,12,'filled'); hold on;
plot(t,X*beta,'k-','LineWidth',1.5); plot(t,X*beta_true,'r--');
xlabel('Predictor'); ylabel('Response'); title('Heteroskedastic synthetic regression');
subplot(1,2,2); histogram(draws(:,2),35); hold on;
xline(beta_true(2),'r--','True slope');
xline(ci(1,2),'b:','Lower'); xline(ci(2,2),'b:','Upper');
xlabel('Slope estimate'); ylabel('Replicates'); title('Wild bootstrap');
% Percentile intervals here are exploratory; assess coverage before inference.

%% Efron bootstrap: IID percentile, basic and BCa intervals
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(108,'twister');
mu=4; x=mu+randn(60,1);
methods={'percentile','basic','bca'};
for i=1:numel(methods)
    [ci,theta,draws]=bootstrap_ci(x,@mean,2000,.95,methods{i},108);
    fprintf('%s: truth %.3f, estimate %.3f, CI [%.3f, %.3f]\n',methods{i},mu,theta,ci(1),ci(2));
end
figure('Name','Classical bootstrap'); histogram(draws,35); hold on;
xline(mu,'r--','True mean'); xline(theta,'k-','Observed mean');
xlabel('Bootstrap mean'); ylabel('Replicates');
title('IID nonparametric bootstrap');

%% Delete-one jackknife: standard error and normal CI of a mean
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(107,'twister');
mu=2; x=mu+randn(40,1);
[ci,out]=jackknife_ci(x,@mean,.95);
fprintf('Jackknife: true mean %.3f, CI [%.3f, %.3f]\n',mu,ci(1),ci(2));
disp(out);
figure('Name','Jackknife'); histogram(x,12); hold on;
xline(mu,'r--','True mean'); xline(mean(x),'k-','Sample mean');
xlabel('Observation'); ylabel('Count'); title('Independent synthetic observations');

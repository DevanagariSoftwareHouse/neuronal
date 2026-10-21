%% Moving-block and stationary bootstrap for autocorrelated LFP-like data
clear; clc; close all;
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','..','..','matlab','path'));
rng(105,'twister');
n=3000; fs=500; t=(0:n-1)'/fs;
% AR(1) noise plus an oscillatory component, illustrative stationary process.
x=zeros(n,1); e=randn(n,1);
for i=2:n, x(i)=.94*x(i-1)+e(i); end
x=x+0.7*sin(2*pi*8*t);
L=100; B=1000;
[ci_m,theta,draws_m]=block_bootstrap_ci(x,@mean,L,B,.95,105,false);
[ci_s,~,draws_s]=block_bootstrap_ci(x,@mean,L,B,.95,105,true);
fprintf('Moving block CI [%.3f, %.3f]; stationary CI [%.3f, %.3f]\n',ci_m(1),ci_m(2),ci_s(1),ci_s(2));
figure('Name','Block bootstrap');
subplot(2,1,1); plot(t,x); xlabel('Time (s)'); ylabel('Signal');
title('Autocorrelated synthetic LFP-like series');
subplot(2,1,2); histogram(draws_m,30); hold on;
histogram(draws_s,30); xline(theta,'k-');
legend('Moving block','Stationary','Observed mean');
xlabel('Bootstrap mean'); ylabel('Replicates');
% Block length and stationarity assumptions require sensitivity analysis.

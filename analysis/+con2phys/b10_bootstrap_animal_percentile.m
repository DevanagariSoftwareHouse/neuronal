%% B10: Single-axis animal bootstrap, percentile interval (synthetic).
% Resample whole independent animals; never flatten trials into animals.
% Output: single_axis_result table in workspace.
rng(810,'twister');
nAnimals = 18; B = 2000; confidence = 0.95;
animalMean = 2 + 0.6*randn(nAnimals,1);
[ci,theta,draws] = bootstrap_ci(animalMean,@mean,B,confidence,'percentile',810);
single_axis_result = table(theta,ci(1),ci(2),ci(2)-ci(1), ...
    'VariableNames',{'Estimate','Lower','Upper','Width'});
disp(single_axis_result);
figure('Name','Animal-axis percentile bootstrap');
histogram(draws,40); hold on; xline(theta,'LineWidth',1.5);
xline(ci(1),'--'); xline(ci(2),'--'); hold off;
xlabel('Animal-level mean'); ylabel('Bootstrap replicates');
title('Single animal axis: percentile CI');

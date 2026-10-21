%% B11: Single-axis animal bootstrap, bias-corrected accelerated CI.
% Output: single_axis_bca table; animals are the independent units.
rng(811,'twister');
nAnimals=18; B=2000; confidence=.95;
animalMean=2+0.6*randn(nAnimals,1);
[ci,theta,draws]=bootstrap_ci(animalMean,@mean,B,confidence,'bca',811);
single_axis_bca=table(theta,ci(1),ci(2),ci(2)-ci(1), ...
    'VariableNames',{'Estimate','Lower','Upper','Width'});
disp(single_axis_bca);
figure('Name','Animal-axis BCa bootstrap');
histogram(draws,40); hold on; xline(theta); xline(ci(1),'--'); xline(ci(2),'--'); hold off;
xlabel('Animal-level mean'); ylabel('Bootstrap replicates');

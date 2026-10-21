%% B13: Paired animal-axis bootstrap, BCa CI (synthetic).
% Difference is computed within animal BEFORE row resampling.
rng(813,'twister');
nAnimals=18; B=2000; confidence=.95;
baseline=2+0.7*randn(nAnimals,1);
treatment=baseline+0.25+0.4*randn(nAnimals,1);
difference=treatment-baseline;
[ci,theta,draws]=bootstrap_ci(difference,@mean,B,confidence,'bca',813);
paired_axis_bca=table(theta,ci(1),ci(2),ci(2)-ci(1), ...
    'VariableNames',{'Difference','Lower','Upper','Width'});
disp(paired_axis_bca);
figure('Name','Paired animal BCa bootstrap');
histogram(draws,40); hold on; xline(0,'--'); xline(theta);
xline(ci(1),'--'); xline(ci(2),'--'); hold off;
xlabel('Within-animal treatment minus baseline'); ylabel('Replicates');

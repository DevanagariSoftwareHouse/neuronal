%% B12: Paired animal-axis bootstrap, percentile CI (synthetic).
% Two measurements from each animal travel together in every draw.
% Output: paired_axis_result table.
rng(812,'twister');
nAnimals=18; B=2000; confidence=.95;
baseline=2+0.7*randn(nAnimals,1);
treatment=baseline+0.25+0.4*randn(nAnimals,1);
paired=[baseline treatment];
difference=paired(:,2)-paired(:,1);
[ci,theta,draws]=bootstrap_ci(difference,@mean,B,confidence,'percentile',812);
paired_axis_result=table(theta,ci(1),ci(2),ci(2)-ci(1), ...
    'VariableNames',{'Difference','Lower','Upper','Width'});
disp(paired_axis_result);
figure('Name','Paired animal percentile bootstrap');
histogram(draws,40); hold on; xline(0,'--'); xline(theta);
xline(ci(1),'--'); xline(ci(2),'--'); hold off;
xlabel('Within-animal treatment minus baseline'); ylabel('Replicates');

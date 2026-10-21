%% B01: Two-stage bootstrap for nested animal/trial data (synthetic).
% Signature: INPUT none (rng seed 701); OUTPUT hierarchical_axes table.
% Resample animals, then trials within each sampled animal. The target
% is the mean of animal means (each animal has equal population weight).
rng(701,'twister'); nAnimals=18; B=2000;
trials=cell(nAnimals,1);
for a=1:nAnimals
    n=12+randi(35);
    trials{a}=0.3+0.8*randn+randn(n,1);
end
animalMeans=cellfun(@mean,trials);
observed=mean(animalMeans);
oneStage=zeros(B,1); twoStage=zeros(B,1);
for b=1:B
    ids=randi(nAnimals,nAnimals,1);
    oneStage(b)=mean(animalMeans(ids));
    tmp=zeros(nAnimals,1);
    for j=1:nAnimals
        x=trials{ids(j)};
        tmp(j)=mean(x(randi(numel(x),numel(x),1)));
    end
    twoStage(b)=mean(tmp);
end
ci1=quantile(oneStage,[.025 .975]);
ci2=quantile(twoStage,[.025 .975]);
hierarchical_axes=table(observed,ci1(1),ci1(2),ci2(1),ci2(2), ...
    'VariableNames',{'Estimate','AnimalLow','AnimalHigh','TwoStageLow','TwoStageHigh'});
disp(hierarchical_axes);
figure('Name','B01 Hierarchical axes');
histogram(oneStage,35); hold on; histogram(twoStage,35);
xlabel('Mean across animals'); ylabel('Count');
legend('Animal-only','Animal then trial');
title('Resampling nested units without flattening');

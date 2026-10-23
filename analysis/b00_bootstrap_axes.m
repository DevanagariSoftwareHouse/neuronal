a00_startup

%% B00: Bootstrap axes, units of inference and storage (synthetic).
% Signature: INPUT none (rng seed 700); OUTPUT axes_demo table.
% Rows represent trials; columns represent time. Neither is automatically
% an independent biological replicate.
rng(700,'twister');
nAnimals=18; nTrials=25; nTime=120; B=1500;
animalEffect=0.9*randn(nAnimals,1);
X=zeros(nAnimals,nTrials,nTime);
for a=1:nAnimals
    X(a,:,:)=animalEffect(a)+0.5*randn(nTrials,nTime);
end
% Collapse time first: statistic is mean trial signal per animal.
trialMean=mean(X,3);
animalMean=mean(trialMean,2);
estimate=mean(animalMean);
naive=zeros(B,1); clustered=zeros(B,1);
for b=1:B
    % Invalid for population-of-animals inference: pooled trials.
    v=trialMean(:); naive(b)=mean(v(randi(numel(v),numel(v),1)));
    % Valid top-level resampling: animals are sampled intact.
    ids=randi(nAnimals,nAnimals,1);
    clustered(b)=mean(animalMean(ids));
end
q=[.025 .975];
ciNaive=quantile(naive,q); ciAnimal=quantile(clustered,q);
axes_demo=table(estimate,ciNaive(1),ciNaive(2),ciAnimal(1),ciAnimal(2), ...
    'VariableNames',{'Estimate','NaiveLow','NaiveHigh','AnimalLow','AnimalHigh'});
disp(axes_demo);
fprintf('Storage axes: animal x trial x time; inferential unit: animal.\n');
figure('Name','B00 Bootstrap axes');
histogram(naive,35,'Normalization','pdf'); hold on;
histogram(clustered,35,'Normalization','pdf');
xlabel('Grand mean'); ylabel('Bootstrap density');
legend('Pooled trials (pseudoreplication)','Animals (cluster bootstrap)');
title('Same data, different resampling axes');

%% B02: Paired animal bootstrap for within-animal condition differences.
% Signature: INPUT none (rng seed 702); OUTPUT paired_axes table.
% Resample complete animal rows; never independently draw the two columns.
rng(702,'twister'); nAnimals=18; B=2000;
baseline=2+randn(nAnimals,1);
treatment=baseline+0.4+0.35*randn(nAnimals,1);
Y=[baseline treatment]; difference=Y(:,2)-Y(:,1);
observed=mean(difference);
paired=zeros(B,1); broken=zeros(B,1);
for b=1:B
    ids=randi(nAnimals,nAnimals,1);
    paired(b)=mean(Y(ids,2)-Y(ids,1));
    % Incorrect for paired inference: destroys covariance.
    ia=randi(nAnimals,nAnimals,1); ib=randi(nAnimals,nAnimals,1);
    broken(b)=mean(Y(ib,2))-mean(Y(ia,1));
end
cp=quantile(paired,[.025 .975]); cb=quantile(broken,[.025 .975]);
paired_axes=table(observed,cp(1),cp(2),cb(1),cb(2), ...
    'VariableNames',{'Difference','PairedLow','PairedHigh','UnpairedLow','UnpairedHigh'});
disp(paired_axes);
figure('Name','B02 Paired axes');
histogram(paired,35); hold on; histogram(broken,35);
xlabel('Condition difference'); ylabel('Count');
legend('Paired animal bootstrap','Broken pairing');
title('Preserving within-animal pairing');

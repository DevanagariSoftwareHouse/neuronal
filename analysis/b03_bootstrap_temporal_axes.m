%% B03: Circular moving-block bootstrap for dependent time samples.
% Signature: INPUT none (rng seed 703); OUTPUT temporal_axes table.
% Illustrates a stationary AR(1) process. Not for arbitrary event-locked
% nonstationary signals; use trial/animal summaries when appropriate.
rng(703,'twister'); n=2500; phi=.85; blockLength=50; B=1500;
x=zeros(n,1); innovations=randn(n,1);
for t=2:n, x(t)=phi*x(t-1)+innovations(t); end
iid=zeros(B,1); block=zeros(B,1);
for b=1:B
    iid(b)=mean(x(randi(n,n,1)));
    starts=randi(n,ceil(n/blockLength),1);
    indices=zeros(ceil(n/blockLength)*blockLength,1);
    for k=1:numel(starts)
        range=(k-1)*blockLength+(1:blockLength);
        indices(range)=mod(starts(k)-1+(0:blockLength-1),n)+1;
    end
    block(b)=mean(x(indices(1:n)));
end
ciIid=quantile(iid,[.025 .975]); ciBlock=quantile(block,[.025 .975]);
temporal_axes=table(mean(x),ciIid(1),ciIid(2),ciBlock(1),ciBlock(2), ...
    'VariableNames',{'Estimate','IidLow','IidHigh','BlockLow','BlockHigh'});
disp(temporal_axes);
figure('Name','B03 Temporal axes');
histogram(iid,35); hold on; histogram(block,35);
xlabel('Time-series mean'); ylabel('Count');
legend('IID samples','Circular blocks');
title('Temporal autocorrelation changes uncertainty');

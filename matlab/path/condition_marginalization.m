function result = condition_marginalization(activity,labels)
%CONDITION_MARGINALIZATION Separate condition means from trial residuals.
% Primitive used in demixing and dDR; not a complete dPCA algorithm.
%
%   SYNTAX
%     result = condition_marginalization(activity,labels)
%
%   INPUTS
%     activity: Finite trials-by-features matrix with at least 2 trials.
%     labels: One condition label per trial.
%
%   OUTPUTS
%     result: Struct with conditions, group_index, condition_means, counts, noise_residual
%       (trials-by-features), and grand_mean.
%
%   EXAMPLE
%     activity = randn(20,4); labels = repelem([1;2],10);
%     result = condition_marginalization(activity,labels);
%     % noise_residual subtracts the mean of each trial's condition.
%
x=double(activity); labels=labels(:);
assert(size(x,1)==numel(labels) && size(x,1)>=2 && all(isfinite(x(:))));
[conditions,~,g]=unique(labels);
k=numel(conditions); p=size(x,2);
means=zeros(k,p); counts=zeros(k,1);
for i=1:k
    block=x(g==i,:);
    means(i,:)=mean(block,1);
    counts(i)=size(block,1);
end
result.conditions=conditions;
result.group_index=g;
result.condition_means=means;
result.counts=counts;
result.noise_residual=bsxfun(@minus,x,means(g,:));
result.grand_mean=mean(x,1);
end

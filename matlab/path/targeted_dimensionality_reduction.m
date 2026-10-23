function model = targeted_dimensionality_reduction(activity,labels)
%TARGETED_DIMENSIONALITY_REDUCTION dDR signal and noise plane.
% Heller & David (2022), doi:10.1371/journal.pone.0271136.
% Use training data only; never fit projection using held-out trials.
%
%   SYNTAX
%     model = targeted_dimensionality_reduction(activity,labels)
%
%   INPUTS
%     activity: Finite trials-by-units matrix with >=2 units.
%     labels: One label per trial; exactly 2 conditions with >=2 trials each and nonzero mean
%       difference.
%
%   OUTPUTS
%     model: Struct with basis (units-by-2 signal/noise axes), center (1-by-units), scores
%       (trials-by-2), conditions and note; errors if noise direction is unresolved.
%
%   EXAMPLE
%     rng(7); labels = repelem([1;2],20); x = randn(40,5); x(21:end,1)=x(21:end,1)+1;
%     model = targeted_dimensionality_reduction(x,labels);
%     % Learn this basis only from training trials in a decoding workflow.
%
x=double(activity); labels=labels(:);
assert(size(x,1)==numel(labels) && size(x,2)>=2 && all(isfinite(x(:))));
c=condition_marginalization(x,labels);
assert(numel(c.conditions)==2 && all(c.counts>=2),'Two conditions, >=2 trials each');
delta=c.condition_means(2,:)-c.condition_means(1,:);
assert(norm(delta)>0,'No population mean difference');
signal=delta(:)/norm(delta);
[~,~,v]=svd(c.noise_residual,'econ');
noise=v(:,1)-signal*(signal'*v(:,1));
if norm(noise)<1e-10 && size(v,2)>=2
    noise=v(:,2)-signal*(signal'*v(:,2));
end
assert(norm(noise)>1e-10,'Noise direction unresolved');
basis=[signal noise/norm(noise)];
model.basis=basis;
model.center=mean(x,1);
model.scores=bsxfun(@minus,x,model.center)*basis;
model.conditions=c.conditions;
model.note='Two-condition dDR; test generalization with held-out trials';
end

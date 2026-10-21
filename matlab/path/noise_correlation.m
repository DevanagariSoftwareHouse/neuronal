function [correlation,residual] = noise_correlation(trial_counts,condition)
%NOISE_CORRELATION Trial residual correlations, subtracting each condition mean.
% Cohen & Kohn (2011). Trial x units counts and trial condition labels.
%
%   SYNTAX
%     [correlation,residual] = noise_correlation(trial_counts,condition)
%
%   INPUTS
%     trial_counts: Finite trials-by-units matrix.
%     condition: One condition label per trial.
%
%   OUTPUTS
%     correlation: Unit-by-unit Pearson residual correlations; constant residual columns
%       produce NaN.
%     residual: Trials-by-units counts after subtracting each condition mean.
%
%   EXAMPLE
%     rng(7); counts = randi([0 5],40,3); condition = repelem([1;2],20);
%     [r, residual] = noise_correlation(counts,condition);
%     % Each residual column is a unit, not a trial.
%
x=double(trial_counts);
assert(size(x,1)==numel(condition) && all(isfinite(x(:))));
condition=condition(:); [~,~,groups]=unique(condition);
residual=x;
for k=1:max(groups)
    selected=groups==k;
    residual(selected,:)=bsxfun(@minus,x(selected,:),mean(x(selected,:),1));
end
correlation=corrcoef(residual);
end

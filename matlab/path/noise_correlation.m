function [correlation,residual] = noise_correlation(trial_counts,condition)
%NOISE_CORRELATION Trial residual correlations, subtracting each condition mean.
% Cohen & Kohn (2011). Trial x units counts and trial condition labels.
%
%   SIGNATURE DESCRIPTION
%     trial_counts — the trial counts value; expected shape, units, and constraints are stated in the notes above.
%     condition — the condition value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     correlation — the returned value; see the summary above for meaning and units.
%     residual — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [correlation, residual] = noise_correlation(trial_counts, condition);
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

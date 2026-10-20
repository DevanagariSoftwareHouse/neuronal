function factor = spike_count_fano(trial_counts)
%SPIKE_COUNT_FANO Variance-to-mean of spike counts across repeated trials.
% Each column is one unit/condition; mix conditions only with justification.
%
%   SIGNATURE DESCRIPTION
%     trial_counts — the trial counts value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     factor — the returned factor; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     factor = spike_count_fano(trial_counts);
%
x=double(trial_counts);
assert(ismatrix(x) && size(x,1)>=2 && all(isfinite(x(:))) && all(x(:)>=0));
means=mean(x,1); factor=var(x,0,1)./means;
factor(means==0)=NaN;
end

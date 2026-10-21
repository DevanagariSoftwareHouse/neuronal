function factor = spike_count_fano(trial_counts)
%SPIKE_COUNT_FANO Variance-to-mean of spike counts across repeated trials.
% Each column is one unit/condition; mix conditions only with justification.
%
%   SYNTAX
%     factor = spike_count_fano(trial_counts)
%
%   INPUTS
%     trial_counts: Finite nonnegative trials-by-units/conditions matrix with >=2 rows.
%
%   OUTPUTS
%     factor: Row vector of sample variance divided by mean; NaN for zero-mean columns.
%
%   EXAMPLE
%     counts = [1 2;2 3;3 4;2 3];
%     factor = spike_count_fano(counts);
%     % Compare trials with matched exposure durations and conditions.
%
x=double(trial_counts);
assert(ismatrix(x) && size(x,1)>=2 && all(isfinite(x(:))) && all(x(:)>=0));
means=mean(x,1); factor=var(x,0,1)./means;
factor(means==0)=NaN;
end

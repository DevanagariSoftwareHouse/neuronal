function [design,valid_bins] = spike_history_design(spike_counts,lags)
%SPIKE_HISTORY_DESIGN Causal spike-count regressors for coupled Poisson GLMs.
% Truccolo et al. (2005), Pillow et al. (2008).
% Input: time bins x recorded units (counts, not spike timestamps).
% Each column j,l corresponds to unit j at time t-l, l >= 1.
% No contemporaneous counts are used; this is not causal identification.
%
%   SYNTAX
%     [design,valid_bins] = spike_history_design(spike_counts,lags)
%
%   INPUTS
%     spike_counts: Finite nonnegative time-bin-by-unit matrix.
%     lags: Positive integer number of previous bins; at least 4 response bins must remain.
%
%   OUTPUTS
%     design: (bins-lags)-by-(units*lags) matrix; column (unit-1)*lags+lag contains that unit
%       at t-lag; <=1e7 elements.
%     valid_bins: Column of response indices lags+1:bins (1-based).
%
%   EXAMPLE
%     counts = reshape(1:40,20,2);
%     [design, valid_bins] = spike_history_design(counts,3);
%     % design(:,1) is unit 1 one bin before each valid response bin.
%
counts=double(spike_counts);
[n,units]=size(counts);
assert(ismatrix(counts) && n>=4 && units>=1 && ...
    all(isfinite(counts(:))) && all(counts(:)>=0));
assert(isscalar(lags) && lags==floor(lags) && lags>=1 && ...
    n-lags>=4);
valid_bins=(lags+1:n)';
rows=numel(valid_bins); columns=units*lags;
assert(rows*columns<=1e7,'Use fewer bins, units, or lags');
design=zeros(rows,columns);
for unit=1:units
    for lag=1:lags
        col=(unit-1)*lags+lag;
        design(:,col)=counts(valid_bins-lag,unit);
    end
end
end

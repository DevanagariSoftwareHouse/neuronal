function [lags_s,counts] = crosscorrelogram(spikes_a,spikes_b,start_s,stop_s,bin_s,max_lag_s)
%CROSSCORRELOGRAM Lagged binned coincidence counts, without trial correction.
% Conventions: xcorr(a,b), positive lag means a follows b.
%
%   SYNTAX
%     [lags_s,counts] = crosscorrelogram(spikes_a,spikes_b,start_s,stop_s,bin_s,max_lag_s)
%
%   INPUTS
%     spikes_a: Finite spike timestamps in seconds.
%     spikes_b: Finite spike timestamps in seconds, same time origin.
%     start_s: Inclusive exposure start in seconds.
%     stop_s: Exclusive exposure end in seconds, greater than start_s.
%     bin_s: Positive bin width in seconds.
%     max_lag_s: Lag limit in seconds, rounded to bins; at least one bin and less than
%       recording length.
%
%   OUTPUTS
%     lags_s: Column lag axis in seconds.
%     counts: Raw binned coincidence counts; positive lag means A follows B.
%
%   Requires Signal Processing Toolbox (xcorr).
%
%   EXAMPLE
%     a = [0.12 0.52 1.02]; b = [0.10 0.50 1.00];
%     [lags_s, counts] = crosscorrelogram(a,b,0,2,0.01,0.1);
%     % The delayed A train contributes near +0.02 s.
%
[a,~,~]=spike_bin_counts(spikes_a,start_s,stop_s,bin_s);
[b,~,~]=spike_bin_counts(spikes_b,start_s,stop_s,bin_s);
lag_bins=round(max_lag_s/bin_s);
assert(lag_bins>=1 && lag_bins<numel(a),'Invalid lag limit');
counts=xcorr(double(a),double(b),lag_bins);
lags_s=(-lag_bins:lag_bins)'*bin_s;
end

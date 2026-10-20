function [lags_s,counts] = autocorrelogram(spike_times,start_s,stop_s,bin_s,max_lag_s)
%AUTOCORRELOGRAM Binned spike-train autocorrelation (count coincidences).
% Bin width determines resolution; central zero-lag includes self-pairs.
%
%   SYNTAX
%     [lags_s,counts] = autocorrelogram(spike_times,start_s,stop_s,bin_s,max_lag_s)
%
%   INPUTS
%     spike_times: Finite timestamps in seconds.
%     start_s: Exposure start in seconds (included).
%     stop_s: Exposure end in seconds (excluded); must exceed start_s.
%     bin_s: Positive bin width in seconds.
%     max_lag_s: Maximum lag in seconds, rounded to bins; at least one bin and less than the
%       binned recording length.
%
%   OUTPUTS
%     lags_s: Column of negative-to-positive lag times in seconds.
%     counts: Raw binned coincidence counts; central lag includes self-pairs.
%
%   Requires Signal Processing Toolbox (xcorr).
%
%   EXAMPLE
%     spikes = [0.1 0.3 0.31 0.8 1.2];
%     [lags_s, counts] = autocorrelogram(spikes,0,2,0.01,0.1);
%     % counts is unnormalized; the central peak includes self-pairs.
%
[b,~,~]=spike_bin_counts(spike_times,start_s,stop_s,bin_s);
lag_bins=round(max_lag_s/bin_s);
assert(lag_bins>=1 && lag_bins<numel(b),'Invalid lag limit');
counts=xcorr(double(b),lag_bins);
lags_s=(-lag_bins:lag_bins)'*bin_s;
end

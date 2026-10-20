function [lags_s,counts] = autocorrelogram(spike_times,start_s,stop_s,bin_s,max_lag_s)
%AUTOCORRELOGRAM Binned spike-train autocorrelation (count coincidences).
% Bin width determines resolution; central zero-lag includes self-pairs.
%
%   SIGNATURE DESCRIPTION
%     spike_times — spike/event timestamps in seconds.
%     start_s — start of the half-open analysis interval, in seconds.
%     stop_s — end of the half-open analysis interval, in seconds.
%     bin_s — bin width in seconds.
%     max_lag_s — the max lag s value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     lags_s — the returned value; see the summary above for meaning and units.
%     counts — event/count values in the bins or trials described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [lags_s, counts] = autocorrelogram(spike_times, start_s, stop_s, bin_s, max_lag_s);
%
[b,~,~]=spike_bin_counts(spike_times,start_s,stop_s,bin_s);
lag_bins=round(max_lag_s/bin_s);
assert(lag_bins>=1 && lag_bins<numel(b),'Invalid lag limit');
counts=xcorr(double(b),lag_bins);
lags_s=(-lag_bins:lag_bins)'*bin_s;
end

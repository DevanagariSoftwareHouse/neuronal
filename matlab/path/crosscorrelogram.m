function [lags_s,counts] = crosscorrelogram(spikes_a,spikes_b,start_s,stop_s,bin_s,max_lag_s)
%CROSSCORRELOGRAM Lagged binned coincidence counts, without trial correction.
% Conventions: xcorr(a,b), positive lag means a follows b.
%
%   SIGNATURE DESCRIPTION
%     spikes_a — the spikes a value; expected shape, units, and constraints are stated in the notes above.
%     spikes_b — the spikes b value; expected shape, units, and constraints are stated in the notes above.
%     start_s — start of the half-open analysis interval, in seconds.
%     stop_s — end of the half-open analysis interval, in seconds.
%     bin_s — bin width in seconds.
%     max_lag_s — the max lag s value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     lags_s — the returned value; see the summary above for meaning and units.
%     counts — event/count values in the bins or trials described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [lags_s, counts] = crosscorrelogram(spikes_a, spikes_b, start_s, stop_s, bin_s, max_lag_s);
%
[a,~,~]=spike_bin_counts(spikes_a,start_s,stop_s,bin_s);
[b,~,~]=spike_bin_counts(spikes_b,start_s,stop_s,bin_s);
lag_bins=round(max_lag_s/bin_s);
assert(lag_bins>=1 && lag_bins<numel(a),'Invalid lag limit');
counts=xcorr(double(a),double(b),lag_bins);
lags_s=(-lag_bins:lag_bins)'*bin_s;
end

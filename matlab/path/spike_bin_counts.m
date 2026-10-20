function [counts,centers,edges] = spike_bin_counts(spike_times,start_s,stop_s,bin_s)
%SPIKE_BIN_COUNTS Count events in half-open [start,stop) bins.
% Truccolo et al. (2005): discrete count representation for point-process GLMs.
% Empty trains are valid; nonfinite timestamps are discarded by spike_counts_edges.
%
%   SIGNATURE DESCRIPTION
%     spike_times — spike/event timestamps in seconds.
%     start_s — start of the half-open analysis interval, in seconds.
%     stop_s — end of the half-open analysis interval, in seconds.
%     bin_s — bin width in seconds.
%   RETURNS
%     counts — event/count values in the bins or trials described above.
%     centers — the returned value; see the summary above for meaning and units.
%     edges — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [counts, centers, edges] = spike_bin_counts(spike_times, start_s, stop_s, bin_s);
%
validateattributes(spike_times,{'numeric'},{'real'});
assert(isempty(spike_times) || isvector(spike_times));
validateattributes(start_s,{'numeric'},{'scalar','real','finite'});
validateattributes(stop_s,{'numeric'},{'scalar','real','finite','>',start_s});
validateattributes(bin_s,{'numeric'},{'scalar','real','finite','positive'});
% Tolerance is in bin-count units; do not discard a complete decimal bin.
nbins=floor((stop_s-start_s)/bin_s+1e-9);
assert(nbins>=1,'Insufficient recording duration');
edges=start_s+(0:nbins)*bin_s;
% A rounded complete last bin must never include a spike at stop_s.
edges(end)=min(edges(end),stop_s);
counts=spike_counts_edges(spike_times,edges);
centers=(edges(1:end-1).'+edges(2:end).')/2;
end

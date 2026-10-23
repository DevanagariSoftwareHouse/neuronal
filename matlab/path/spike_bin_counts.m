function [counts,centers,edges] = spike_bin_counts(spike_times,start_s,stop_s,bin_s)
%SPIKE_BIN_COUNTS Count events in half-open [start,stop) bins.
% Truccolo et al. (2005): discrete count representation for point-process GLMs.
% Empty trains are valid; nonfinite timestamps are discarded by spike_counts_edges.
%
%   SYNTAX
%     [counts,centers,edges] = spike_bin_counts(spike_times,start_s,stop_s,bin_s)
%
%   INPUTS
%     spike_times: Real timestamp vector in seconds; empty accepted, nonfinite entries
%       discarded.
%     start_s: Finite inclusive recording start in seconds.
%     stop_s: Finite exclusive recording stop >start_s.
%     bin_s: Positive bin duration in seconds; at least one complete bin required.
%
%   OUTPUTS
%     counts: Complete-bins-by-1 count vector.
%     centers: Complete-bins-by-1 time centers in seconds.
%     edges: Row vector of bin boundaries; an incomplete recording tail is omitted.
%
%   EXAMPLE
%     [counts, centers, edges] = spike_bin_counts([0.1 0.5 0.9 1],0,1,0.25);
%     % The spike at 1 s is excluded; counts are [1;0;1;1].
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

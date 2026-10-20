function counts = spike_counts_edges(spike_times,edges)
%SPIKE_COUNTS_EDGES Event counts for explicit, possibly irregular [left,right) bins.
% Empty spike trains are valid. Nonfinite timestamps are excluded.
%
%   SYNTAX
%     counts = spike_counts_edges(spike_times,edges)
%
%   INPUTS
%     spike_times: Real timestamp vector in seconds; empty accepted, nonfinite entries
%       discarded.
%     edges: Strictly increasing finite edge vector in seconds with >=2 entries.
%
%   OUTPUTS
%     counts: (numel(edges)-1)-by-1 counts in [left,right) bins; events at final edge are
%       excluded.
%
%   EXAMPLE
%     counts = spike_counts_edges([0 0.2 0.5 1 NaN],[0 0.5 1]);
%     % Returns [2;1]; 1 and NaN are excluded.
%
validateattributes(spike_times,{'numeric'},{'real'});
assert(isempty(spike_times) || isvector(spike_times),'Expected one spike train.');
validateattributes(edges,{'numeric'},{'vector','real','finite','increasing'});
assert(numel(edges)>=2,'At least two edges are required.');
t=double(spike_times(:)); edges=double(edges(:).');
t=t(isfinite(t) & t>=edges(1) & t<edges(end));
counts=histcounts(t,edges).';
end

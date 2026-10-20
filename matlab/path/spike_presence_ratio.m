function out = spike_presence_ratio(times,start_seconds,stop_seconds,bin_seconds)
%SPIKE_PRESENCE_RATIO Fraction of time bins containing any sorted spike.
% Analog to SpikeInterface presence ratio. Empty bins may reflect low rate.
%
%   SYNTAX
%     out = spike_presence_ratio(times,start_seconds,stop_seconds,bin_seconds)
%
%   INPUTS
%     times: Finite spike timestamps in seconds.
%     start_seconds: Finite inclusive interval start.
%     stop_seconds: Finite interval end >start_seconds.
%     bin_seconds: Positive bin duration; at least one complete bin required.
%
%   OUTPUTS
%     out: Struct: ratio (occupied-bin fraction), counts (column), edges_seconds (column),
%       unused_tail_seconds.
%
%   EXAMPLE
%     out = spike_presence_ratio([0.1 0.2 2.2],0,4,1);
%     % Two of four complete one-second bins are occupied, giving ratio 0.5.
%
times=double(times(:));
assert(all(isfinite(times)) && stop_seconds>start_seconds && ...
    all(isfinite([start_seconds stop_seconds bin_seconds])) && bin_seconds>0);
n=floor((stop_seconds-start_seconds)/bin_seconds);
assert(n>=1,'At least one complete time bin required');
edges=start_seconds+(0:n)*bin_seconds;
counts=histcounts(times(times>=edges(1) & times<edges(end)),edges);
out.ratio=mean(counts>0);
out.counts=counts(:);
out.edges_seconds=edges(:);
out.unused_tail_seconds=stop_seconds-edges(end);
end

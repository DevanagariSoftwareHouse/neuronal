function intervals_s = interspike_intervals(spike_times)
%INTERSPIKE_INTERVALS Successive sorted event separations (seconds).
% Duplicate times yield 0; investigate recording/sample precision.
%
%   SYNTAX
%     intervals_s = interspike_intervals(spike_times)
%
%   INPUTS
%     spike_times: Finite timestamps in seconds; unsorted and empty inputs are allowed.
%
%   OUTPUTS
%     intervals_s: Column of successive differences after sorting; empty for fewer than 2
%       events.
%
%   EXAMPLE
%     intervals_s = interspike_intervals([0.4 0.1 0.2]);
%     % Returns [0.1;0.2] seconds.
%
t=double(spike_times(:));
assert(all(isfinite(t)),'Spike times must be finite');
intervals_s=diff(sort(t));
end

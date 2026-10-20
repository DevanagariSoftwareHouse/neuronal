function intervals_s = interspike_intervals(spike_times)
%INTERSPIKE_INTERVALS Successive sorted event separations (seconds).
% Duplicate times yield 0; investigate recording/sample precision.
%
%   SIGNATURE DESCRIPTION
%     spike_times — spike/event timestamps in seconds.
%   RETURNS
%     intervals_s — the returned intervals_s; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     intervals_s = interspike_intervals(spike_times);
%
t=double(spike_times(:));
assert(all(isfinite(t)),'Spike times must be finite');
intervals_s=diff(sort(t));
end

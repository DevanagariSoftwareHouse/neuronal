function rate_hz = firing_rate(spike_times,start_s,stop_s)
%FIRING_RATE Mean firing rate from spike timestamps in seconds.
% Uses a half-open exposure interval; excludes events at stop_s.
%
%   SYNTAX
%     rate_hz = firing_rate(spike_times,start_s,stop_s)
%
%   INPUTS
%     spike_times: Finite timestamps in seconds, flattened; empty input is allowed.
%     start_s: Finite inclusive interval start in seconds.
%     stop_s: Finite exclusive interval end, strictly greater than start_s.
%
%   OUTPUTS
%     rate_hz: Scalar number of included spikes divided by exposure duration (spikes/s).
%
%   EXAMPLE
%     rate_hz = firing_rate([0.1 0.5 1.0],0,1);
%     % rate_hz is 2: the spike at the exclusive stop is omitted.
%
assert(isfinite(start_s) && isfinite(stop_s) && stop_s>start_s);
x=double(spike_times(:));
assert(all(isfinite(x)),'Spike times must be finite');
rate_hz=sum(x>=start_s & x<stop_s)/(stop_s-start_s);
end

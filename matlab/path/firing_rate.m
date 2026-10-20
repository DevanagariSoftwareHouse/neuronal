function rate_hz = firing_rate(spike_times,start_s,stop_s)
%FIRING_RATE Mean firing rate from spike timestamps in seconds.
% Uses a half-open exposure interval; excludes events at stop_s.
%
%   SIGNATURE DESCRIPTION
%     spike_times — spike/event timestamps in seconds.
%     start_s — start of the half-open analysis interval, in seconds.
%     stop_s — end of the half-open analysis interval, in seconds.
%   RETURNS
%     rate_hz — rate in spikes per second (Hz).
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     rate_hz = firing_rate(spike_times, start_s, stop_s);
%
assert(isfinite(start_s) && isfinite(stop_s) && stop_s>start_s);
x=double(spike_times(:));
assert(all(isfinite(x)),'Spike times must be finite');
rate_hz=sum(x>=start_s & x<stop_s)/(stop_s-start_s);
end

function surrogate = jitter_spike_surrogate(spike_times,window_s,origin_s)
%JITTER_SPIKE_SURROGATE Uniform jitter inside fixed non-overlapping windows.
% Amarasingham et al. (2012): simplified conditional-jitter null.
% Preserves total spikes per window; use caller-controlled random seed.
%
%   SIGNATURE DESCRIPTION
%     spike_times — spike/event timestamps in seconds.
%     window_s — window duration in seconds.
%     origin_s — the origin s value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     surrogate — the returned surrogate; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     surrogate = jitter_spike_surrogate(spike_times, window_s, origin_s);
%
if nargin<3 || isempty(origin_s), origin_s=0; end
t=double(spike_times(:));
assert(all(isfinite(t)) && window_s>0 && isfinite(origin_s));
start=origin_s+floor((t-origin_s)/window_s)*window_s;
surrogate=sort(start+rand(size(t))*window_s);
end

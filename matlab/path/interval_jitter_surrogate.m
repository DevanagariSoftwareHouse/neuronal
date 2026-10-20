function y = interval_jitter_surrogate(spike_times,window_s,origin_s)
%INTERVAL_JITTER_SURROGATE Fixed-bin conditional uniform spike resampling.
% Preserves number of spikes in each aligned window, not refractory periods.
% Amarasingham et al. (2012). Does NOT implement pattern jitter.
%
%   SIGNATURE DESCRIPTION
%     spike_times — spike/event timestamps in seconds.
%     window_s — window duration in seconds.
%     origin_s — the origin s value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     y — the returned y; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     y = interval_jitter_surrogate(spike_times, window_s, origin_s);
%
if nargin<3||isempty(origin_s), origin_s=0; end
t=double(spike_times(:));
assert(all(isfinite(t))&&isscalar(window_s)&&window_s>0);
assert(isscalar(origin_s)&&isfinite(origin_s));
left=origin_s+floor((t-origin_s)/window_s)*window_s;
y=sort(left+window_s*rand(size(t)));
end

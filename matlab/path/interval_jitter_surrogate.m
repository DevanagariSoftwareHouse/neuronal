function y = interval_jitter_surrogate(spike_times,window_s,origin_s)
%INTERVAL_JITTER_SURROGATE Fixed-bin conditional uniform spike resampling.
% Preserves number of spikes in each aligned window, not refractory periods.
% Amarasingham et al. (2012). Does NOT implement pattern jitter.
if nargin<3||isempty(origin_s), origin_s=0; end
t=double(spike_times(:));
assert(all(isfinite(t))&&isscalar(window_s)&&window_s>0);
assert(isscalar(origin_s)&&isfinite(origin_s));
left=origin_s+floor((t-origin_s)/window_s)*window_s;
y=sort(left+window_s*rand(size(t)));
end

function y = interval_jitter_surrogate(spike_times,window_s,origin_s)
%INTERVAL_JITTER_SURROGATE Fixed-bin conditional uniform spike resampling.
% Preserves number of spikes in each aligned window, not refractory periods.
% Amarasingham et al. (2012). Does NOT implement pattern jitter.
%
%   SYNTAX
%     y = interval_jitter_surrogate(spike_times,window_s,origin_s)
%
%   INPUTS
%     spike_times: Finite timestamps in seconds.
%     window_s: Positive width of fixed aligned jitter intervals in seconds.
%     origin_s: Finite alignment origin in seconds; default 0.
%
%   OUTPUTS
%     y: Sorted column of resampled timestamps, preserving counts per aligned window.
%
%   EXAMPLE
%     rng(7); spikes = [0.01;0.03;0.12;0.18];
%     y = interval_jitter_surrogate(spikes,0.1,0);
%     % Each 100-ms interval retains its original spike count.
%
if nargin<3||isempty(origin_s), origin_s=0; end
t=double(spike_times(:));
assert(all(isfinite(t))&&isscalar(window_s)&&window_s>0);
assert(isscalar(origin_s)&&isfinite(origin_s));
left=origin_s+floor((t-origin_s)/window_s)*window_s;
y=sort(left+window_s*rand(size(t)));
end

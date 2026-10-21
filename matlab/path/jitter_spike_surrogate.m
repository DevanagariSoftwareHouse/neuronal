function surrogate = jitter_spike_surrogate(spike_times,window_s,origin_s)
%JITTER_SPIKE_SURROGATE Uniform jitter inside fixed non-overlapping windows.
% Amarasingham et al. (2012): simplified conditional-jitter null.
% Preserves total spikes per window; use caller-controlled random seed.
%
%   SYNTAX
%     surrogate = jitter_spike_surrogate(spike_times,window_s,origin_s)
%
%   INPUTS
%     spike_times: Finite timestamps in seconds.
%     window_s: Positive width of fixed aligned jitter intervals in seconds.
%     origin_s: Finite alignment origin in seconds; default 0.
%
%   OUTPUTS
%     surrogate: Sorted column of resampled timestamps, preserving counts per aligned window.
%
%   EXAMPLE
%     rng(7); spikes = [0.01;0.03;0.12;0.18];
%     y = jitter_spike_surrogate(spikes,0.1,0);
%     % Each 100-ms interval retains its original spike count.
%
if nargin<3 || isempty(origin_s), origin_s=0; end
t=double(spike_times(:));
assert(all(isfinite(t)) && window_s>0 && isfinite(origin_s));
start=origin_s+floor((t-origin_s)/window_s)*window_s;
surrogate=sort(start+rand(size(t))*window_s);
end

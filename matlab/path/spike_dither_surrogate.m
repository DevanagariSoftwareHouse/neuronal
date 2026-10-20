function y = spike_dither_surrogate(spike_times,halfwidth_s)
%SPIKE_DITHER_SURROGATE Spike-centered independent uniform dithering.
% This is NOT an exact conditional interval-jitter null.
% Platkiewicz, Stark & Amarasingham (2017) discuss false positives.
%
%   SYNTAX
%     y = spike_dither_surrogate(spike_times,halfwidth_s)
%
%   INPUTS
%     spike_times: Finite timestamps in seconds.
%     halfwidth_s: Positive scalar dither half-width in seconds.
%
%   OUTPUTS
%     y: Sorted column with each event independently displaced in +/-halfwidth_s; no
%       recording-boundary clipping.
%
%   EXAMPLE
%     rng(7); y = spike_dither_surrogate([0.1;0.3;0.5],0.02);
%     % Dithering can move events outside a recording and does not preserve bin counts.
%
t=double(spike_times(:));
assert(all(isfinite(t))&&isscalar(halfwidth_s)&&halfwidth_s>0);
y=sort(t+(2*rand(size(t))-1)*halfwidth_s);
end

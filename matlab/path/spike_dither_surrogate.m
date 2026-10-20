function y = spike_dither_surrogate(spike_times,halfwidth_s)
%SPIKE_DITHER_SURROGATE Spike-centered independent uniform dithering.
% This is NOT an exact conditional interval-jitter null.
% Platkiewicz, Stark & Amarasingham (2017) discuss false positives.
%
%   SIGNATURE DESCRIPTION
%     spike_times — spike/event timestamps in seconds.
%     halfwidth_s — the halfwidth s value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     y — the returned y; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     y = spike_dither_surrogate(spike_times, halfwidth_s);
%
t=double(spike_times(:));
assert(all(isfinite(t))&&isscalar(halfwidth_s)&&halfwidth_s>0);
y=sort(t+(2*rand(size(t))-1)*halfwidth_s);
end

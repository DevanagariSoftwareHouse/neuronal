function y = spike_dither_surrogate(spike_times,halfwidth_s)
%SPIKE_DITHER_SURROGATE Spike-centered independent uniform dithering.
% This is NOT an exact conditional interval-jitter null.
% Platkiewicz, Stark & Amarasingham (2017) discuss false positives.
t=double(spike_times(:));
assert(all(isfinite(t))&&isscalar(halfwidth_s)&&halfwidth_s>0);
y=sort(t+(2*rand(size(t))-1)*halfwidth_s);
end

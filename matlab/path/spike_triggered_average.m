function [average,lags_s,used] = spike_triggered_average(signal,spike_times,srate,pre_s,post_s)
%SPIKE_TRIGGERED_AVERAGE Compatibility name for event_triggered_average.
% [AVG, LAGS, USED] = SPIKE_TRIGGERED_AVERAGE(X, TIMES, FS, PRE, POST)
% Nearest-sample anchors, complete windows only, column-vector outputs.
% Use event_triggered_average for spikes, stimuli or other event timestamps.
%
%   SYNTAX
%     [average,lags_s,used] = spike_triggered_average(signal,spike_times,srate,pre_s,post_s)
%
%   INPUTS
%     signal: Finite sampled vector.
%     spike_times: Finite event timestamps in seconds, first sample at zero.
%     srate: Positive sampling rate in Hz.
%     pre_s: Nonnegative duration before each event in seconds.
%     post_s: Nonnegative duration after each event in seconds.
%
%   OUTPUTS
%     average: Column mean over complete event windows; all NaN if none retained.
%     lags_s: Column relative time axis in seconds, both rounded endpoints included.
%     used: Scalar number of complete windows averaged.
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     [average, lags_s, used] = spike_triggered_average(x,[1 2 3],fs,0.1,0.2);
%     % Event centers use round(time*fs)+1, and incomplete windows are skipped.
%
[average,lags_s,used] = event_triggered_average(signal,spike_times,srate,pre_s,post_s);
end

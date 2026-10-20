function [average,lags_s,used] = spike_triggered_average(signal,spike_times,srate,pre_s,post_s)
%SPIKE_TRIGGERED_AVERAGE Compatibility name for event_triggered_average.
% [AVG, LAGS, USED] = SPIKE_TRIGGERED_AVERAGE(X, TIMES, FS, PRE, POST)
% Nearest-sample anchors, complete windows only, column-vector outputs.
% Use event_triggered_average for spikes, stimuli or other event timestamps.
[average,lags_s,used] = event_triggered_average(signal,spike_times,srate,pre_s,post_s);
end

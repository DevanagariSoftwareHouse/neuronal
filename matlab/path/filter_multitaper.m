function [power,frequency,time] = filter_multitaper(x,fs,varargin)
%FILTER_MULTITAPER Thomson windowed PSD, in signal-units squared per Hz.
% [P,F,T] = filter_multitaper(X,FS,WINDOW_SECONDS,OVERLAP,NW,K)
% Reuses MULTITAPER_SPECTROGRAM. P: frequencies-by-windows-by-channels.
% This estimates power; it does not return a filtered voltage waveform.
% Example: [p,f,t]=filter_multitaper(randn(5000,2),500,1,.5,3,5);
[power,frequency,time]=multitaper_spectrogram(x,fs,varargin{:});
end

function [counts, lags_s, info] = event_aligned_raster(rastergram, event_times_s, srate, window_s, cluster_row, varargin)
%EVENT_ALIGNED_RASTER Compatibility name for one-row event_aligned_segments.
% [COUNTS, LAGS, INFO] = EVENT_ALIGNED_RASTER(S, EVENTS, FS, WINDOW, ROW)
% Preserves containing-bin alignment, row-by-sample layout and the original
% INFO.cluster_row field. Boundary is 'nan' (default) or 'drop'.
% Use event_aligned_segments for continuous signals and multiple rows.
validateattributes(rastergram, {'numeric'}, {'2d','real'});
validateattributes(cluster_row, {'numeric'}, ...
    {'scalar','real','integer','>=',1,'<=',size(rastergram,1)});
p = inputParser;
addParameter(p,'Boundary','nan',@(x)ischar(x)||(isstring(x)&&isscalar(x)));
parse(p,varargin{:});
[counts,lags_s,meta] = event_aligned_segments(rastergram,event_times_s, ...
    srate,window_s,cluster_row,'SampleDim',2,'Anchor','containing', ...
    'Boundary',p.Results.Boundary);
info = struct('event_times_s',meta.event_times_s, ...
    'event_indices',meta.event_indices,'center_samples',meta.center_samples, ...
    'valid_bins',meta.valid_bins,'cluster_row',double(cluster_row), ...
    'boundary',meta.boundary,'sampling_rate_hz',meta.sampling_rate_hz);
end

function [counts, lags_s, info] = event_aligned_raster(rastergram, event_times_s, srate, window_s, cluster_row, varargin)
%EVENT_ALIGNED_RASTER Compatibility name for one-row event_aligned_segments.
% [COUNTS, LAGS, INFO] = EVENT_ALIGNED_RASTER(S, EVENTS, FS, WINDOW, ROW)
% Preserves containing-bin alignment, row-by-sample layout and the original
% INFO.cluster_row field. Boundary is 'nan' (default) or 'drop'.
% Use event_aligned_segments for continuous signals and multiple rows.
%
%   SYNTAX
%     [counts, lags_s, info] = event_aligned_raster(rastergram, event_times_s, srate, window_s, cluster_row, varargin)
%
%   INPUTS
%     rastergram: Cluster-by-recording-sample numeric count matrix, dense or sparse.
%     event_times_s: Finite event timestamps in seconds; empty vector is allowed.
%     srate: Positive bin sampling rate in Hz.
%     window_s: [start end] relative seconds, e.g. [-0.1 0.2], both rounded endpoints included.
%     cluster_row: 1-based raster row, not a cluster ID.
%     varargin: Boundary name/value: nan (default) pads partial windows; drop retains only
%       complete windows.
%
%   OUTPUTS
%     counts: Retained-events-by-lags dense counts, with NaNs for missing bins.
%     lags_s: 1-by-lags relative times in seconds.
%     info: Struct with event_times_s, event_indices, center_samples, valid_bins, cluster_row,
%       boundary and sampling_rate_hz.
%
%   EXAMPLE
%     raster = sparse(1,[101 201 301],1,1,500);
%     [counts, lags_s, info] = event_aligned_raster(raster,[0.2;0.4],500, ...
%         [-0.1 0.1],1,'Boundary','drop');
%     % info.event_indices maps retained rows back to the supplied events.
%
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

function [counts, lags_s, info] = event_aligned_raster(rastergram, event_times_s, srate, window_s, cluster_row, varargin)
%EVENT_ALIGNED_RASTER Extract a trial x peri-event bin count matrix.
% [COUNTS, LAGS_S, INFO] = EVENT_ALIGNED_RASTER(RASTER, EVENTS, FS,
%                                              [PRE POST], CLUSTER_ROW)
% RASTER is cluster x recording sample (see spike_raster_sparse).
% EVENTS are arbitrary timestamps in seconds relative to the same origin.
% CLUSTER_ROW is a 1-based row index, NOT necessarily the original cluster ID.
% The window endpoints are rounded to samples and INCLUDED in the output.
% Event time zero is the recording bin floor(EVENT*FS)+1.
% Boundary (name/value): 'nan' [default] keeps partial events, padding
% missing samples with NaN; 'drop' removes events lacking a full window.
% COUNTS has events x lags layout, preserving multiple spikes per bin.
% INFO.event_indices references positions in the supplied EVENTS vector.
validateattributes(rastergram, {'numeric'}, {'2d','real'});
assert(isempty(event_times_s) || isvector(event_times_s), 'Expected a vector or empty input.');
validateattributes(event_times_s, {'numeric'}, {'real','finite'});
validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(window_s, {'numeric'}, {'vector','numel',2,'real','finite'});
validateattributes(cluster_row, {'numeric'}, ...
    {'scalar','real','integer','>=',1,'<=',size(rastergram,1)});
assert(window_s(1) <= window_s(2), 'Window start must precede window end.');

p = inputParser;
addParameter(p, 'Boundary', 'nan', ...
    @(x) ischar(x) || (isstring(x) && isscalar(x)));
parse(p, varargin{:});
boundary = validatestring(p.Results.Boundary, {'nan','drop'});

offsets = round(double(window_s(1))*double(srate)) : ...
          round(double(window_s(2))*double(srate));
lags_s = offsets / double(srate);
events = double(event_times_s(:));
n_events = numel(events);
event_indices = (1:n_events)';
n_bins = numel(lags_s);

% Only build indices for one cluster at a time to avoid a dense
% cluster x trial x lag tensor for long recordings.
centers = floor(events * double(srate)) + 1;
if n_events == 0
    indices = zeros(0,n_bins);
else
    indices = bsxfun(@plus, centers, offsets);
end
in_recording = indices >= 1 & indices <= size(rastergram,2);

if strcmp(boundary, 'drop')
    keep = all(in_recording,2);
    indices = indices(keep,:);
    in_recording = in_recording(keep,:);
    events = events(keep);
    centers = centers(keep);
    event_indices = event_indices(keep);
end

counts = nan(size(indices));
if any(in_recording(:))
    counts(in_recording) = full(rastergram(cluster_row, indices(in_recording)));
end
info = struct('event_times_s', events, 'event_indices', event_indices, ...
    'center_samples', centers, 'valid_bins', in_recording, ...
    'cluster_row', double(cluster_row), 'boundary', boundary, ...
    'sampling_rate_hz', double(srate));
end

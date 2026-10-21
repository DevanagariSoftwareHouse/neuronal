function h = plot_event_raster(counts, lags_s)
%PLOT_EVENT_RASTER Compatibility display for event-by-bin spike counts.
% H = PLOT_EVENT_RASTER(COUNTS, LAGS) uses log(1+count) and transparent NaNs.
% Use plot_event_aligned with an explicit Scale for other sampled signals.
%
%   SYNTAX
%     h = plot_event_raster(counts, lags_s)
%
%   INPUTS
%     counts: Nonempty events-by-bins numeric matrix, nonnegative values or NaN padding.
%     lags_s: Finite vector in seconds, one value per column.
%
%   OUTPUTS
%     h: Image graphics handle displaying log(1+counts); NaNs are transparent. Draws in the
%       current axes.
%
%   EXAMPLE
%     counts = [0 1 2 0 1;1 0 1 0 0]; lags_s = -0.2:0.1:0.2;
%     figure; h = plot_event_raster(counts,lags_s);
%     % Color encodes transformed counts; multiple spikes remain distinguishable.
%
validateattributes(counts, {'numeric'}, {'2d','real'});
assert(all(isnan(counts(:)) | (isfinite(counts(:)) & counts(:)>=0)), ...
    'Counts must be nonnegative or NaN padding.');
h = plot_event_aligned(counts,lags_s,'Scale','log1p', ...
    'ValueLabel','log(1 + spike count)');
end

function h = plot_event_raster(counts, lags_s)
%PLOT_EVENT_RASTER Display event x bin spike counts without losing multiples.
% H = PLOT_EVENT_RASTER(COUNTS, LAGS_S) plots log(1+count) for visibility.
% NaN-padded samples are transparent. Raw COUNTS are not modified.
validateattributes(counts, {'numeric'}, {'2d','real'});
validateattributes(lags_s, {'numeric'}, {'vector','real','finite'});
assert(all(isnan(counts(:)) | (isfinite(counts(:)) & counts(:)>=0)), ...
    'Counts must be nonnegative or NaN padding.');
assert(size(counts,2)==numel(lags_s),'Lag vector must match raster columns.');
assert(size(counts,1)>0 && size(counts,2)>0,'No events to plot.');
h = imagesc(double(lags_s(:).'), 1:size(counts,1), log1p(double(counts)));
set(h,'AlphaData',double(isfinite(counts)));
axis xy
xlabel('Time relative to event (s)')
ylabel('Event / trial')
cb = colorbar;
ylabel(cb,'log(1 + spike count)')
xline(0,'w--');
end

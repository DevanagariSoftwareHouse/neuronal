function h = plot_event_aligned(values, lags_s, varargin)
%PLOT_EVENT_ALIGNED Display an event x lag matrix as an image, one row per event.
% H = PLOT_EVENT_ALIGNED(VALUES, LAGS_S) for a slice of event_aligned_segments.
% Name/value: 'Scale' = 'auto' (default), 'log1p' or 'linear';
%             'ValueLabel' = colorbar label (default follows the scale).
% 'auto' shows log(1+value) when every finite value is a nonnegative
% integer (event counts: multiples are compressed, never lost) and the raw
% values otherwise (LFP, envelopes). NaN-padded samples are transparent.
% VALUES are not modified; the display is not an estimator.
% See also event_aligned_segments.
validateattributes(values, {'numeric'}, {'2d','real'});
validateattributes(lags_s, {'numeric'}, {'vector','real','finite'});
assert(size(values,2)==numel(lags_s),'Lag vector must match columns.');
assert(size(values,1)>0 && size(values,2)>0,'No events to plot.');
is_text = @(x) ischar(x) || (isstring(x) && isscalar(x));
p = inputParser;
addParameter(p,'Scale','auto',is_text);
addParameter(p,'ValueLabel','',is_text);
parse(p,varargin{:});
scale = validatestring(p.Results.Scale,{'auto','log1p','linear'});
v = double(values);
finite = isfinite(v);
is_count = all(v(finite) >= 0 & v(finite) == round(v(finite)));
if strcmp(scale,'auto')
    if is_count, scale = 'log1p'; else, scale = 'linear'; end
end
if strcmp(scale,'log1p')
    assert(all(v(finite) >= 0),'log1p scale requires nonnegative values.');
    shown = log1p(v);
    default_label = 'log(1 + count)';
else
    shown = v;
    default_label = 'Value';
end
label = char(p.Results.ValueLabel);
if isempty(label), label = default_label; end
h = imagesc(double(lags_s(:).'), 1:size(v,1), shown);
set(h,'AlphaData',double(finite));
axis xy
xlabel('Time relative to event (s)')
ylabel('Event / trial')
cb = colorbar;
ylabel(cb,label)
xline(0,'w--');
end

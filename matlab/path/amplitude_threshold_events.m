function [times_s, events] = amplitude_threshold_events(envelope, srate, threshold, varargin)
%AMPLITUDE_THRESHOLD_EVENTS Extract threshold excursions from an envelope.
% [TIMES, EVENTS] = AMPLITUDE_THRESHOLD_EVENTS(ENVELOPE, FS, THRESHOLD)
% Name/value: 'Anchor' = 'peak' (default), 'onset', or 'midpoint';
%             'MinDuration' = minimum duration in seconds (default 0);
%             'MinSeparation' = minimum distance between anchors (default 0).
% Excursions are maximal contiguous runs of ENVELOPE >= THRESHOLD.
% Timestamp zero corresponds to the first sample. [start_s,stop_s)
% describes each run, with stop_s one sample after the last active sample.
% This is a general envelope detector, NOT a validated ripple classifier.
validateattributes(envelope, {'numeric'}, {'vector','real','finite','nonnegative'});
validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(threshold, {'numeric'}, {'scalar','real','finite','nonnegative'});
p = inputParser;
addParameter(p,'Anchor','peak',@(x)ischar(x)||(isstring(x)&&isscalar(x)));
addParameter(p,'MinDuration',0,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0);
addParameter(p,'MinSeparation',0,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0);
parse(p,varargin{:});
anchor = validatestring(p.Results.Anchor, {'peak','onset','midpoint'});
min_duration = double(p.Results.MinDuration);
min_separation = double(p.Results.MinSeparation);

x = double(envelope(:));
active = x >= double(threshold);
starts = find(diff([false;active]) == 1);
stops = find(diff([active;false]) == -1);
rows = zeros(numel(starts),5);
n = 0;
last_anchor = -inf;
for k = 1:numel(starts)
    first = starts(k);
    last = stops(k);
    start_s = (first-1)/double(srate);
    stop_s = last/double(srate);
    if (stop_s-start_s) < min_duration
        continue
    end
    [peak_amp, peak_idx] = max(x(first:last));
    peak_s = (first+peak_idx-2)/double(srate);
    switch anchor
        case 'onset'
            anchor_s = start_s;
        case 'midpoint'
            anchor_s = (start_s+stop_s)/2;
        otherwise
            anchor_s = peak_s;
    end
    if anchor_s-last_anchor < min_separation
        continue
    end
    n = n+1;
    rows(n,:) = [start_s,stop_s,peak_s,peak_amp,anchor_s];
    last_anchor = anchor_s;
end
events = array2table(rows(1:n,:), 'VariableNames', ...
    {'start_s','stop_s','peak_s','peak_amplitude','anchor_s'});
times_s = events.anchor_s;
end

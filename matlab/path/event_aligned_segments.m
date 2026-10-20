function [segments, lags_s, info] = event_aligned_segments(signal, event_times_s, srate, window_s, rows, varargin)
%EVENT_ALIGNED_SEGMENTS Extract event x lag segments from any sampled signal.
% [SEGMENTS, LAGS_S, INFO] = EVENT_ALIGNED_SEGMENTS(SIGNAL, EVENTS, FS,
%                                                  [PRE POST], ROWS)
% SIGNAL is row x sample on the grid t = (k-1)/FS, k = 1,...,N: sparse
% counts (see sparse_count_matrix), LFP channels, envelopes or phases.
% A vector, row or column, is treated as one row.
% EVENTS are arbitrary timestamps in seconds relative to the same origin:
% stimuli, behavior, phase crossings, threshold excursions, spikes.
% ROWS are 1-based row indices, NOT necessarily original labels; [] or
% omitted selects all rows. Prefer few rows of a long sparse matrix.
% The window endpoints are rounded to samples and INCLUDED in the output.
% Name/value:
%   'Boundary'  'nan' [default] keeps partial events, padding missing
%               samples with NaN; 'drop' removes events lacking a full window.
%   'Anchor'    'containing' [default]: lag zero is the sample containing
%               the event, floor(EVENT*FS)+1; 'nearest': round(EVENT*FS)+1.
%   'SampleDim' 2 [default] for row x sample; 1 for sample x row blocks
%               (the neuronal_read layout), indexed without transposing.
% SEGMENTS is events x lags x rows (events x lags for one row), class
% double. Values are copied unchanged: counts keep multiple events per bin,
% and missing samples are NaN rather than zero.
% INFO.event_indices references positions in the supplied EVENTS vector.
% See also sparse_count_matrix, event_triggered_average, plot_event_aligned.
assert(ismatrix(signal) && (isnumeric(signal) || islogical(signal)) && isreal(signal), ...
    'Signal must be a real numeric or logical matrix.');
assert(isempty(event_times_s) || isvector(event_times_s), 'Expected a vector or empty input.');
validateattributes(event_times_s, {'numeric'}, {'real','finite'});
validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(window_s, {'numeric'}, {'vector','numel',2,'real','finite'});
assert(window_s(1) <= window_s(2), 'Window start must precede window end.');

is_text = @(x) ischar(x) || (isstring(x) && isscalar(x));
p = inputParser;
addParameter(p, 'Boundary', 'nan', is_text);
addParameter(p, 'Anchor', 'containing', is_text);
addParameter(p, 'SampleDim', 2, @(x) isnumeric(x) && isscalar(x) && any(x == [1 2]));
parse(p, varargin{:});
boundary = validatestring(p.Results.Boundary, {'nan','drop'});
anchor = validatestring(p.Results.Anchor, {'containing','nearest'});
sample_dim = double(p.Results.SampleDim);
if isvector(signal)
    % A vector has one row whatever its orientation.
    sample_dim = 1 + double(size(signal,1) == 1 || isscalar(signal));
end
n_samples = size(signal, sample_dim);
n_rows = size(signal, 3 - sample_dim);

if nargin < 5 || isempty(rows)
    rows = 1:n_rows;
end
validateattributes(rows, {'numeric'}, ...
    {'vector','real','integer','>=',1,'<=',n_rows});
rows = double(rows(:)).';

offsets = round(double(window_s(1))*double(srate)) : ...
          round(double(window_s(2))*double(srate));
lags_s = offsets / double(srate);
events = double(event_times_s(:));
n_events = numel(events);
event_indices = (1:n_events)';
n_bins = numel(lags_s);

if strcmp(anchor, 'nearest')
    centers = round(events * double(srate)) + 1;
else
    centers = floor(events * double(srate)) + 1;
end
if n_events == 0
    indices = zeros(0,n_bins);
else
    indices = bsxfun(@plus, centers, offsets);
end
in_recording = indices >= 1 & indices <= n_samples;

if strcmp(boundary, 'drop')
    keep = all(in_recording,2);
    indices = indices(keep,:);
    in_recording = in_recording(keep,:);
    events = events(keep);
    centers = centers(keep);
    event_indices = event_indices(keep);
end

% One row at a time: only the requested event x lag slices become dense.
segments = nan(size(indices,1), n_bins, numel(rows));
wanted = indices(in_recording);
for r = 1:numel(rows)
    if isempty(wanted), break; end
    if sample_dim == 2
        values = signal(rows(r), wanted);
    else
        values = signal(wanted, rows(r));
    end
    slice = nan(size(indices));
    slice(in_recording) = full(double(values));
    segments(:,:,r) = slice;
end
info = struct('event_times_s', events, 'event_indices', event_indices, ...
    'center_samples', centers, 'valid_bins', in_recording, ...
    'rows', rows, 'sample_dim', sample_dim, 'anchor', anchor, ...
    'boundary', boundary, 'sampling_rate_hz', double(srate));
end

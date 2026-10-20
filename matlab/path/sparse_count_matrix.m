function [counts, label_ids, info] = sparse_count_matrix(event_times_s, event_labels, srate, n_samples)
%SPARSE_COUNT_MATRIX Bin labelled timestamps into a sparse label x sample matrix.
% [COUNTS, LABEL_IDS, INFO] = SPARSE_COUNT_MATRIX(TIMES, LABELS, FS, N)
% TIMES are seconds since the recording start; LABELS are the original
% labels of each timestamp (spike clusters, channels, TTL lines, behavior
% codes). Any labelled point process works; spikes are the common case.
% Columns represent half-open intervals [(k-1)/FS, k/FS), k=1,...,N, the
% same grid as a signal sampled at FS from time zero.
% Multiple events in the same bin and label are SUMMED (not binarized).
% Nonfinite and out-of-recording times are discarded. LABEL_IDS lists the
% labels in sorted order, one per COUNTS row, including labels whose
% events were all discarded. Row k of COUNTS is label LABEL_IDS(k).
% See also event_aligned_segments, spike_counts_edges.
assert(isempty(event_times_s) || isvector(event_times_s), 'Expected a vector or empty input.');
validateattributes(event_times_s, {'numeric'}, {'real'});
assert(isempty(event_labels) || isvector(event_labels), 'Expected a vector or empty input.');
validateattributes(event_labels, {'numeric'}, {'real','finite'});
validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(n_samples, {'numeric'}, {'scalar','real','finite','integer','positive'});
assert(numel(event_times_s) == numel(event_labels), ...
    'Timestamps and labels must have equal lengths.');

times = double(event_times_s(:));
[label_ids, ~, rows] = unique(event_labels(:));
duration_s = double(n_samples) / double(srate);
keep = isfinite(times) & times >= 0 & times < duration_s;
cols = floor(times(keep) .* double(srate)) + 1;
% Guard against a floating-point boundary rounding to an invalid column.
good_col = cols >= 1 & cols <= n_samples;
selected_rows = double(rows(keep));
counts = sparse(selected_rows(good_col), cols(good_col), ones(nnz(good_col),1), ...
    numel(label_ids), double(n_samples));

info = struct('sampling_rate_hz', double(srate), ...
    'n_samples', double(n_samples), 'duration_s', duration_s, ...
    'events_input', numel(times), 'events_kept', nnz(good_col), ...
    'events_discarded', numel(times) - nnz(good_col));
end

function [rastergram, cluster_ids, info] = spike_raster_sparse(spike_times_s, spike_clusters, srate, n_samples)
%SPIKE_RASTER_SPARSE Bin timestamped spikes into a sparse cluster x time matrix.
% [RASTERGRAM, CLUSTER_IDS, INFO] = SPIKE_RASTER_SPARSE(TIMES, IDS, FS, N)
% TIMES are seconds since the recording start; IDS are original cluster labels.
% Columns represent half-open intervals [(k-1)/FS, k/FS), k=1,...,N.
% Multiple spikes in the same bin and cluster are SUMMED (not binarized).
% Nonfinite and out-of-recording spike times are discarded. Cluster labels
% remain in sorted order, including clusters whose spikes were discarded.
validateattributes(spike_times_s, {'numeric'}, {'vector','real'});
validateattributes(spike_clusters, {'numeric'}, {'vector','real','finite'});
validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(n_samples, {'numeric'}, {'scalar','real','finite','integer','positive'});
assert(numel(spike_times_s) == numel(spike_clusters), ...
    'Spike timestamps and cluster labels must have equal lengths.');

times = double(spike_times_s(:));
[cluster_ids, ~, rows] = unique(spike_clusters(:));
duration_s = double(n_samples) / double(srate);
keep = isfinite(times) & times >= 0 & times < duration_s;
cols = floor(times(keep) .* double(srate)) + 1;
% Guard against a floating-point boundary rounding to an invalid column.
good_col = cols >= 1 & cols <= n_samples;
selected_rows = double(rows(keep));
rastergram = sparse(selected_rows(good_col), cols(good_col), ones(nnz(good_col),1), ...
    numel(cluster_ids), double(n_samples));

info = struct('sampling_rate_hz', double(srate), ...
    'n_samples', double(n_samples), 'duration_s', duration_s, ...
    'spikes_input', numel(times), 'spikes_kept', nnz(good_col), ...
    'spikes_discarded', numel(times) - nnz(good_col));
end

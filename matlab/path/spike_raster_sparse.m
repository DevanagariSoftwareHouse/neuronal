function [rastergram, cluster_ids, info] = spike_raster_sparse(spike_times_s, spike_clusters, srate, n_samples)
%SPIKE_RASTER_SPARSE Compatibility name for sparse_count_matrix.
% [S, IDS, INFO] = SPIKE_RASTER_SPARSE(TIMES, CLUSTERS, FS, N)
% Preserves the original spikes_* metadata fields. New code should use
% sparse_count_matrix for any labelled point events, including spikes.
%
%   SYNTAX
%     [rastergram, cluster_ids, info] = spike_raster_sparse(spike_times_s, spike_clusters, srate, n_samples)
%
%   INPUTS
%     spike_times_s: Real timestamp vector in seconds; invalid/out-of-range values discarded.
%     spike_clusters: Matching finite numeric cluster labels; labels need not be consecutive.
%     srate: Positive bin sampling rate in Hz.
%     n_samples: Positive integer number of recording bins.
%
%   OUTPUTS
%     rastergram: Sparse clusters-by-n_samples count matrix; multiple events are summed.
%     cluster_ids: Sorted unique original labels, one per raster row, including labels with no
%       retained spikes.
%     info: Struct with sampling_rate_hz, n_samples, duration_s, spikes_input, spikes_kept and
%       spikes_discarded.
%
%   EXAMPLE
%     [raster, ids, info] = spike_raster_sparse([0.1 0.1 0.4],[7 7 42],500,500);
%     % ids=[7;42]; raster(1,51)=2 counts, not a binary flag.
%
[rastergram, cluster_ids, meta] = sparse_count_matrix( ...
    spike_times_s, spike_clusters, srate, n_samples);
info = struct('sampling_rate_hz',meta.sampling_rate_hz, ...
    'n_samples',meta.n_samples,'duration_s',meta.duration_s, ...
    'spikes_input',meta.events_input,'spikes_kept',meta.events_kept, ...
    'spikes_discarded',meta.events_discarded);
end

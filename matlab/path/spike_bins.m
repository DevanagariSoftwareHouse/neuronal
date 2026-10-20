function counts = spike_bins(spikes,edges)
%SPIKE_BINS Bin several spike trains on shared explicit edges.
% COUNTS = SPIKE_BINS(SPIKES, EDGES) with SPIKES a cell array of timestamp
% vectors (seconds), one per unit, returns bins x units counts.
% Each column is spike_counts_edges(SPIKES{u}, EDGES): half-open
% [left,right) bins, empty trains valid, nonfinite timestamps discarded.
% See also spike_counts_edges, sparse_count_matrix, trial_features.
    counts=zeros(numel(edges)-1,numel(spikes));
    for u=1:numel(spikes)
        counts(:,u)=spike_counts_edges(spikes{u},edges);
    end
end

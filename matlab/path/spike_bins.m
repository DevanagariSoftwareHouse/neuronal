function counts = spike_bins(spikes,edges)
%SPIKE_BINS Bin several spike trains on shared explicit edges.
% COUNTS = SPIKE_BINS(SPIKES, EDGES) with SPIKES a cell array of timestamp
% vectors (seconds), one per unit, returns bins x units counts.
% Each column is spike_counts_edges(SPIKES{u}, EDGES): half-open
% [left,right) bins, empty trains valid, nonfinite timestamps discarded.
% See also spike_counts_edges, sparse_count_matrix, trial_features.
%
%   SYNTAX
%     counts = spike_bins(spikes,edges)
%
%   INPUTS
%     spikes: Cell array containing one real spike-time vector per unit, in seconds.
%     edges: Strictly increasing finite bin edges in seconds; >=2 entries.
%
%   OUTPUTS
%     counts: Bins-by-units numeric count matrix, with half-open bins including the last bin.
%
%   EXAMPLE
%     spikes = {[0.1 0.4 0.8], [0.2 0.6]};
%     counts = spike_bins(spikes,0:0.25:1);
%     % Columns follow cell-array unit order, including empty trains.
%
    counts=zeros(numel(edges)-1,numel(spikes));
    for u=1:numel(spikes)
        counts(:,u)=spike_counts_edges(spikes{u},edges);
    end
end

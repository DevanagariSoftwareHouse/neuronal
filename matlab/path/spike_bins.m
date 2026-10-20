function counts = spike_bins(spikes,edges)
%SPIKE_BINS Half-open bin counts for a cell array of spike trains.
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

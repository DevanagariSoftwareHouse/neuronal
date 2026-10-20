function counts = spike_bins(spikes,edges)
%
%   SIGNATURE DESCRIPTION
%     spikes — the spikes value; expected shape, units, and constraints are stated in the notes above.
%     edges — monotonically increasing bin edges in seconds or feature units.
%   RETURNS
%     counts — event/count values in the bins or trials described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     counts = spike_bins(spikes, edges);
%
    counts=zeros(numel(edges)-1,numel(spikes));
    for u=1:numel(spikes)
        counts(:,u)=spike_counts_edges(spikes{u},edges);
    end
end

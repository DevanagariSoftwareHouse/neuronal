
clc
clear
%%
a00_startup

%%
catalog = neuronal_catalog();

%%
d = 1;
data = catalog.data(d);

%%
clc
timestamp = neuronal_memmap(data.file(4));
cluster   = neuronal_memmap(data.file(5));

%%
srate    = double(data.file(1).sampling_rate_hz);
nSamples = double(data.n_lfp_samples);
duration = nSamples / srate;

%%
spikeTimes    = double(timestamp.Data.x(:));
spikeClusters = cluster.Data.x(:);

assert(numel(spikeTimes) == numel(spikeClusters), ...
    'Timestamp and cluster arrays must have equal lengths.');

%%
[rastergram, clusters, raster_info] = spike_raster_sparse( ...
    spikeTimes, spikeClusters, srate, nSamples);
fprintf('Clusters: %d; spikes retained: %d\n',numel(clusters),raster_info.spikes_kept);

%% Extract one cluster at a time, padding events at recording boundaries.
event_times = [data.behavior.trials.stim_start];
for nrn = 1:numel(clusters)
    [counts, lags_s] = event_aligned_raster( ...
        rastergram,event_times,srate,[-1 1],nrn);
    if isempty(counts), continue; end
    plot_event_raster(counts,lags_s);
    title(sprintf('Cluster %g',clusters(nrn)));
    drawnow;
    pause(.1);
end


clc
clear
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
tic

% Map original cluster IDs to contiguous row indices.
[clusters, ~, clusterIndex] = unique(spikeClusters);

% Keep spikes within the LFP recording interval.
valid = isfinite(spikeTimes) & ...
        spikeTimes >= 0 & ...
        spikeTimes < duration;

% Convert timestamps to 1-based sample indices.
timeIndex = floor(spikeTimes(valid) * srate) + 1;

% Corresponding cluster row indices.
clusterIndex = double(clusterIndex(valid));

% Construct sparse spike-count rastergram.
% Repeated indices are automatically summed.
rastergram = sparse( ...
    clusterIndex, ...
    timeIndex, ...
    1, ...
    numel(clusters), ...
    nSamples);

toc

%%
fprintf('Clusters: %d\n', numel(clusters));
fprintf('Time bins: %d\n', nSamples);
fprintf('Spikes retained: %d\n', nnz(valid));
fprintf('Occupied bins: %d\n', nnz(rastergram));

%%
dt = 1/srate;
peristimulus_window = (-1:dt:1);

%%
nof_trials = length(data.behavior.trials);
nof_samples = length(peristimulus_window);
peristimulus_raster = cell(1,nof_trials);
for trial = 1 : nof_trials
    ts = data.behavior.trials(trial).stim_start;
    id = floor((peristimulus_window+ts)*500);
    peristimulus_raster{trial} = rastergram(:,id);
end
%%
for nrn = 1 : 88
peristimulus_neuron_raster = zeros(nof_trials,nof_samples);
for t = 1 : nof_trials
    peristimulus_neuron_raster(t,:) = full(peristimulus_raster{t}(nrn,:));
end
imagesc(peristimulus_window,1:nof_trials,log(peristimulus_neuron_raster))
colorbar
caxis([0,1])
title(nrn)
pause(.1)
end
%%
for n = 1 : 88
[a,v] = xcorr(full(rastergram(n,:)));
figure(1)
set(gcf,'windowstyle','docked')
plot(v,a)
xlim([-200,200])
pause()
end
plot(v,a)
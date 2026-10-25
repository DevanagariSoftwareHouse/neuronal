
%% GPU spike counting demonstration

gpu = gpuDevice;

% Example: one session
dd = 1;
d = data(dd);

waveform_id = d.waveform_id(:);
spike_time = double(d.spike_time.Data.x(:));
spike_id = d.spike_cluster.Data.x(:);

[mapped, neuron_index] = ismember( ...
    spike_id,waveform_id);

% Upload once
t_gpu = gpuArray(spike_time(mapped));
id_gpu = gpuArray(double(neuron_index(mapped)));

n_neurons = numel(waveform_id);

interval = interval_dyadic( ...
    d.n_lfp_samples,d.srate,4,0.5,1);

tic

selected = ...
    t_gpu >= interval.t0 & ...
    t_gpu < interval.t1;

counts_gpu = accumarray( ...
    id_gpu(selected),1, ...
    [n_neurons,1],@sum,0);

counts = gather(counts_gpu);

wait(gpu);
toc

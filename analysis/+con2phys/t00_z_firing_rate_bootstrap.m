run analysis/a00_startup.m

%%
for dd = 1 :numel(data)
data(dd).neuronal_timestamp_id = zeros(1,1);
data(dd).srate = 500
end
%%
for dd = 1 : numel(data)
    d = data(dd);

    neuronal_timestamp_id = arrayfun(@(x)floor(d.srate*d.spike_time.Data.x(d.spike_cluster.Data.x==d.waveform_id(x))),1:size(d.waveform_id,2),'UniformOutput',false);

    d.neuronal_timestamp_id = neuronal_timestamp_id;
    data(dd) = d;

end
%%
seed = 42;

rng(seed, 'twister');
%%


run analysis/a00_startup.m
%%
output_dir = fullfile(neuronal_dir,'data','derived');

st = storage_hdf5( ...
    'root', fullfile(output_dir,'spike_lfp'), ...
    'precision','preserve', ...
    'chunk_samples',4096, ...
    'compression',0, ...
    'overwrite',false);

%%


n_workers = 10;

pool = gcp('nocreate');

if ~isempty(pool) && pool.NumWorkers ~= n_workers
    delete(pool);
    pool = [];
end

if isempty(pool)
    pool = parpool('local',n_workers);
end

tic

%%
clc

dyadic_time_levels = 0 : 15;

partition = @(d,la,ch,dfi,dti)sprintf("session_%d/area_%d/ch_%d/fi_%d/ti_%d",d,la,ch,dfi,dti);

st = storage_create(%insert here the correct code

for d = 1 : numel(data)
    data_dir = fullfile(output_dir,data(d).source_id);
    lfp_areas = {'lfp_1','lfp_2','lfp_3'};
   
    spike_time = double(gpuArray(data(d).spike_time.Data.x));
    spike_id   = int32(gpuArray(data(d).spike_cluster.Data.x(:)));

    assert(numel(spike_time) == numel(spike_id));

    [mapped, neuron_index] = ismember( ...
        spike_id, data(d).waveform_id);

    spike_time   = spike_time(mapped);
    neuron_index = neuron_index(mapped);

    n_neurons = numel(data(d).waveform_id);
   
   for la = 1 : numel(lfp_areas)
      signal_mmap = data(d).(lfp_areas{la});
      [N,n_channels] = size(signal_mmap.Data.x);
      
      for ch = 1 : n_channels
          signal = gpuArray(signal_mmap.Data.x(:,ch));
          
          n_dyadic_frequency_intervals = interval_dyadic(250,1,0:7,0.5);
          for dfi = 1 : n_dyadic_frequency_intervals
              f = interval_dyadic(250,1,0:7,0.5,dfi);

              fd = filter_design('butterworth',500,[f.t0 f.t1],4);
              signal_filtered  = filter_do(signal,500,fd);
              signal_hilbert   = hilbert(signal_filtered);
              signal_angle     = angle(signal_hilbert);
              signal_amplitude = abs(signal_hilbert);
              
              n_dyadic_time_intervals = interval_dyadic(N,500,0:15,0);
              for dti = 1 : n_dyadic_time_intervals
                  t = interval_dyadic(N,500,0:15,0,dti);
                  
                    selected = ...
                        spike_time >= t.t0 & ...
                        spike_time <  t.t1;

                    counts = accumarray( ...
                        neuron_index(selected), ...
                        1, ...
                        [n_neurons,1], ...
                        @sum, ...
                        0 ...
                    );
  
                  output_dirname = partition(d, la, ch, dfi, dti);
                  
                  st = storage_append(st,output_dir + '/spike_count',counts);
                  
                  spike_time_id = floor(spike_time(selected)*500);
                  
                  spike_phase = mean(signal_angle(spike_time_id));
                  
                  st = storage_append(st,output_dir + '/spike_phase',spike_phase);
                  
                  
                  
              end
          end
      end
   end
end

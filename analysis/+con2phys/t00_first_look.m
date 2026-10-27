neuronal_path = '/home/gois/Insync/jhenriquetdg@gmail.com/Google Drive/matlab/neuronal';
run(fullfile(neuronal_path,'analysis','a00_startup.m'))
% Legacy EEGLAB eegfilt is explicitly opt-in (GPL-2.0-or-later).
addpath(fullfile(neuronal_path,'matlab','third_party'))
%%
for d = 1 : 18
    data(d).duration = data(d).n_lfp_samples/500;
    for wid = 1:numel(data(d).waveform_id)
        id = data(d).waveform_id(wid) == data(d).spike_cluster.Data.x;
        n_spikes = sum(id);
        data(d).spike_count(wid) = n_spikes;
    end
end
%%
spike_count = {data.spike_count}
session_duration = [data.duration]

%%
spike_frequency = cell(1,18)
for s = 1 : 18
    spike_frequency{s} = spike_count{s}/session_duration(s);
end
spike_area = {data.waveform_area};
spike_area = cellfun(@(x)int64(x),spike_area,'UniformOutput',false);
%%
spike_frequency = cell2mat(spike_frequency)
spike_area = cell2mat(spike_area)

%%

boxplot(spike_frequency,spike_area)

%%
band = struct();

band(1).name  = 'delta';
band(1).lo    = 0.5;
band(1).hi    = 3.8;
band(1).color = 'g';

band(2).name  = 'theta';
band(2).lo    = 4.1;
band(2).hi    = 10;
band(2).color = 'r';

%%
times          = struct();
times(1).init  = 1/500;
times(1).end   = 100;
times(1).srate = 500;

for dd = 1 : numel(data)
    d = data(dd);

    for t = 1 : numel(times)
        time = times(t);
        time.t = time.init:(1/time.srate):time.end;
        time.id = unique(floor(time.init*time.srate:time.end*time.srate));

        d.time(t) = time;

        for cc = 1 : size(d.lfp_1.Data.x,2)
            sample = d.lfp_1.Data.x(time.id,cc);
            for b = 1 : numel(band)
                d.time(t).band(b).sample = eegfilt(sample',time.srate,band(b).lo,band(b).hi);
            end
        end
        data(dd).time = d.time;
    end

end

%%

for b = 1 : numel(band)
    h = hilbert(zscore(band(b).sample));
    band(b).amplitude = abs(h);
    band(b).phase = angle(h);
end
%%

si = data(1).spike_time.Data.x >= time.init;
se = data(1).spike_time.Data.x <= time.end;
spike_time = data(1).spike_time.Data.x(si & se);
spike_id = floor(spike_time*time.srate);

%%
b = 2
[A, B] = meshgrid(-time.srate:1*time.srate,spike_id);
ID = A+B;
%%
IDid = ID>=time.id(1) & ID<=time.id(end);

%%
ID = ID(all(IDid,2),all(IDid,1));
%%

%%
imagesc(band(2).amplitude(ID)')

%%

% Índices dos spikes relativos à janela selecionada.
Fs = time.srate;
t0 = time.t(1);
spike_idx = round((spike_time(:) - t0) * Fs) + 1;

% Janela de -1 a +1 s ao redor de cada spike.
offsets = -Fs:Fs;
idx = spike_idx + offsets;

% Manter apenas spikes cuja janela inteira cabe no sinal.
valid = all(idx >= 1 & idx <= numel(band(2).amplitude), 2);
idx = idx(valid, :);

% Cada linha é um spike; cada coluna é um instante relativo ao spike.
sample_by_spike = band(2).sample(idx);
amplitude_by_spike = band(2).amplitude(idx);
close all
figure
set(gcf,'windowstyle','docked')
subplot(3,1,1:2)
imagesc(offsets / Fs, 1:size(amplitude_by_spike, 1), amplitude_by_spike)
axis xy
xlabel('Tempo relativo ao spike (s)')
ylabel('Spike')
title('Amplitude theta alinhada aos spikes')
colorbar

%%
summed_amplitude = sum(amplitude_by_spike,2);
bin_edges = quantile(summed_amplitude,0:.25:1);
id_bin = sum(summed_amplitude>bin_edges,2);
bins = unique(id_bin);

for b = 1 : numel(bins)
    id = id_bin==bins(b);
    plot(offsets,zscore(mean(sample_by_spike(id,:),1)))
    hold on

end
hold off
grid on
xlim([-150 150])
%%
phase_by_spike = band(2).phase(idx);

figure
imagesc(offsets / Fs, 1:size(phase_by_spike, 1), phase_by_spike)
axis xy
xlabel('Tempo relativo ao spike (s)')
ylabel('Spike')
title('Fase theta alinhada aos spikes')
colorbar
hold off
legend()
%%
clf

summed_amplitude = sum(amplitude_by_spike,2);
bin_edges = quantile(summed_amplitude,0:.25:1);
id_bin = sum(summed_amplitude>bin_edges,2);
bins = unique(id_bin);

for b = 1 : numel(bins)
    id = id_bin==bins(b);
    plot(offsets,unwrap(mean(phase_by_spike(id,:)),1))
    hold on

end

%%

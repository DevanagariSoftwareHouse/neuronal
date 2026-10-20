
matlab_dir = '/home/gois/Insync/jhenriquetdg@gmail.com/Google Drive/matlab/';
run(fullfile(matlab_dir,'startup.m'))

matlab_dir = '/home/gois/Insync/jhenriquetdg@gmail.com/Google Drive/matlab/';
run(fullfile(matlab_dir,'neuronal/startup.m'))
run(fullfile(matlab_dir,'neuronal/analysis/a00_startup.m'))

%%
catalog = neuronal_catalog()
data = catalog.data
%%
for d = 1 : numel(data)
    for f = 1 : numel(data(d).file)
        data(d).(data(d).file(f).name) = neuronal_memmap(data(d).file(f))
    end
    data(d).waveform_id = data(d).brain_areas.cluster_id
    data(d).waveform_area = data(d).brain_areas.brain_area
    
end
%%

data(1)

%%
time_of_analysis = struct()
time_of_analysis(1).init = 1/500
time_of_analysis(1).end = 100
time_of_analysis(1).srate = 500

for t = 1 : data(1).n_lfp_samples/500
    time = time_of_analysis(1)
    time.t = time.init:(1/time.srate):time.end
    time.id = unique(floor(time.init*time.srate:time.end*time.srate))
    
    break
    
end
%%
for t = 1 : numel(time_of_analysis)
    sample = data(1).lfp_1.Data.x(time.id,15)
end

%%

WINDOW = time.srate*10;
NOVERLAP = WINDOW/2;
F = 0:1:200;
Fs = 500;
[Pxx,F] = pwelch(sample,WINDOW,NOVERLAP,F,Fs);
plot(F,Pxx)
xlim([0 20])

%%

delta = bandpass_lfp(sample,500,[1 4])
theta = bandpass_lfp(sample,500,[4 10])

%%
clf
plot(time.t,delta,'g')
hold on
plot(time.t,theta,'r')
plot(time.t,sample,'k')

%%

band = struct()
band(1).name = 'delta'
band(1).lo   = 0.1
band(1).hi = 3.8
band(1).color = 'g'
band(2).name = 'theta'
band(2).lo   = 4.1
band(2).hi = 10
band(2).color = 'r'
band(3).name = 'low'
band(3).lo   = .1
band(3).hi = 10
band(3).color = 'p'

%%
for b = 1 : numel(band)
    band(b).sample = eegfilt(sample',time.srate,band(b).lo,band(b).hi);
end
%%

clf
plot(time.t,zscore(sample),'k')

hold on
for b = 1 : numel(band)
plot(time.t,zscore(band(b).sample),'r')
end
hold off
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


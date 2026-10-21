%% Real cluster-average waveforms: descriptive shape, not spike-level quality.
r=struct('mode','real average waveforms');
assert(numel(d.file)>=6,'battle:skip','No average waveforms descriptor.');
m=neuronal_memmap(d.file(6),repo);
W=double(neuronal_read(m))'; clear m
r.pca=spike_waveform_pca(W,3);
r.waveform_fs=double(d.file(6).sampling_rate_hz);
r.width_ms=nan(size(W,1),1);
for j=1:size(W,1)
    r.width_ms(j)=waveform_trough_to_peak(W(j,:),r.waveform_fs);
end
r.note='Sampling rate comes from digest metadata; verify original acquisition rate. Average templates cannot establish per-spike SNR or isolation.';
if cfg.plots
    figure('Name','CON2PHYS average waveforms'); plot((0:size(W,2)-1)/r.waveform_fs*1000,W(1:min(12,end),:)'); xlabel('ms');
end

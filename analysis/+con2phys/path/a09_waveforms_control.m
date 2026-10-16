%% Synthetic broadband control: no AP extraction from the 500-Hz LFP.
% Known event times quantify detection agreement; not CON2PHYS sorting accuracy.
r=struct('mode','synthetic broadband control'); fs=30000; n=fs*3;
raw=.1*randn(2,n); truth=(.1:.05:2.9)'; ix=round(truth*fs)+1;
u=-30:60; shape=-3*exp(-(u/8).^2)+exp(-((u-20)/12).^2);
for j=1:numel(ix), raw(:,ix(j)+u)=raw(:,ix(j)+u)+[1;.7]*shape; end
[r.times,r.indices,r.threshold]=spike_threshold_detection(raw(1,:),fs,5,.002);
r.agreement=spike_sorting_agreement(truth,r.times,.0005);
[waves,r.kept]=spike_waveform_extraction(raw,r.indices,30,60);
assert(size(waves,1)>=2);
[r.template,r.sem]=spike_waveform_average(waves);
r.snr=spike_waveform_snr(r.template,raw(:,1:1000));
flat=reshape(double(waves(:,1,:)),size(waves,1),[]);
r.pca=spike_waveform_pca(flat,3);
[r.template_id,r.similarity]=template_match_waveforms(flat,r.template(1,:));
r.width_ms=waveform_trough_to_peak(r.template(1,:),fs);
assert(r.agreement.true_positives>0);
if cfg.plots
    figure('Name','Synthetic AP control'); plot(u/fs*1000,r.template'); xlabel('ms'); ylabel('Synthetic voltage');
end

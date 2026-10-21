%% Oscillation descriptors and event alignment, with explicit edge exclusion.
r=struct('mode','real');
theta=bandpass_lfp(c.x,c.fs,[4 12]);
[phase,amp]=analytic_phase(theta);
inside=(1:numel(theta))'>2*c.fs & (1:numel(theta))'<=numel(theta)-2*c.fs;
r.cycles=cycle_by_cycle(theta(inside),c.fs); % Times relative to cropped segment.
r.moments=lfp_envelope_moments(c.lfp{1}',c.fs,'StepSeconds',1,'TimeOriginSeconds',c.origin);
r.bosc=bosc_detect(c.x,c.fs,4:2:30,.95,3,6);
r.wavelet=morlet_wavelet(c.x,c.fs,8,6);
[r.episodes,r.mask,r.fraction]=oscillation_episode(r.bosc.wavelet_power(3,:)>r.bosc.power_threshold(3) & r.bosc.valid_mask(3,:),c.fs,8,3);
r.phase_events=phase_crossing_events(phase,c.fs,0,.05);
[r.amplitude_events,r.excursions]=amplitude_threshold_events(amp,c.fs,quantile(amp(inside),.9),'MinDuration',.05);
r.phase_events=r.phase_events(r.phase_events>=2 & r.phase_events<c.T-2);
r.amplitude_events=r.amplitude_events(r.amplitude_events>=2 & r.amplitude_events<c.T-2);
% Ripple candidates only; restricted below Nyquist, no physiological validation.
r.ripples=ripple_candidate_events(c.lfp{3}(:,1),c.fs,[100 min(200,.45*c.fs)],2,4);
[r.raster,r.ids,r.raster_info]=spike_raster_sparse(c.s,ones(size(c.s)),c.fs,numel(c.x));
r.alignment=cell(1,3); ev={c.events,r.phase_events,r.amplitude_events};
for j=1:3
    [rr,ll,ii]=event_aligned_raster(r.raster,ev{j},c.fs,[-.5 .5],1,'Boundary','drop');
    r.alignment{j}=struct('counts',rr,'lags',ll,'info',ii);
end
if ~isempty(c.events)
    [r.psth_time,r.psth,r.trial_counts]=peri_event_histogram(c.s,c.events,-.5:.02:.5);
else
    r.psth_note='No valid trial starts in this excerpt; choose another start_s.';
end
[r.sta,r.sta_lags,r.sta_used]=spike_triggered_average(c.x,c.s,c.fs,.2,.2);
if cfg.plots && ~isempty(r.alignment{1}.counts)
    figure('Name','Trial-start raster'); plot_event_raster(r.alignment{1}.counts,r.alignment{1}.lags);
end

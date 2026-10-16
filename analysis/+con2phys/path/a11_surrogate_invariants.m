%% Null generators: demonstrate what each preserves on real inputs.
r=struct('mode','real data / surrogate controls'); x=c.x(1:min(4096,numel(c.x)));
r.phase=phase_randomized_surrogate(x);
r.aaft=aaft_surrogate(x); [r.iaaft,r.convergence]=iaaft_surrogate(x,100,1e-6);
r.multivariate=multivariate_phase_surrogate([x c.y(1:numel(x))]);
r.shift=circular_shift_surrogate(x,round(c.fs));
r.blocks=block_shuffle_surrogate(x,round(c.fs));
r.jitter=interval_jitter_surrogate(c.s,.02,0);
r.jitter_alias=jitter_spike_surrogate(c.s,.02,0);
r.dither=spike_dither_surrogate(c.s,.01);
% Dither may leave the interval; do not silently clip and change its null.
trial_spikes=cell(size(c.windows,1),1);
for j=1:numel(trial_spikes)
    s=c.spikes{c.selected(1)};
    trial_spikes{j}=s(s>=c.windows(j,1)&s<c.windows(j,2))-c.windows(j,1);
end
assert(numel(trial_spikes)>=2,'battle:skip','Need two trials for trial shuffling.');
r.trials=trial_shuffle_surrogate(trial_spikes);
r.local=local_permutation_surrogate(c.C(:,1),c.C(:,2),10);
assert(max(abs(sort(x)-sort(r.aaft)))<1e-10);
assert(max(abs(sort(x)-sort(r.iaaft)))<1e-10);
assert(isequal(floor(c.s/.02),floor(r.jitter/.02)),'Interval jitter changed window counts.');
r.phase_spectrum_relative_error=norm(abs(fft(x))-abs(fft(r.phase)))/norm(fft(x));
assert(r.phase_spectrum_relative_error<1e-10);

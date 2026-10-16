%% Phase/PAC/spike-field descriptors. Common drive and waveform shape confound them.
r=struct('mode','real');
a=bandpass_lfp(c.x,c.fs,[4 12]); b=bandpass_lfp(c.y,c.fs,[4 12]);
[pa,~,za]=analytic_phase(a); [pb,~,zb]=analytic_phase(b);
[~,ga]=analytic_phase(bandpass_lfp(c.x,c.fs,[30 80]));
keep=(2*c.fs+1):(numel(a)-2*c.fs);
r.plv=phase_locking_value(pa(keep),pb(keep));
r.pli=phase_lag_index(pa(keep)-pb(keep));
% wPLI expects independent-segment cross-spectra, not instantaneous phases.
L=round(2*c.fs); nseg=floor(numel(c.x)/L);
fa=fft(reshape(c.x(1:L*nseg),L,nseg)); fb=fft(reshape(c.y(1:L*nseg),L,nseg));
fbin=round(8*L/c.fs)+1;
r.wpli=weighted_phase_lag_index(fa(fbin,:).*conj(fb(fbin,:)));
[r.mi,r.amplitude_by_phase]=modulation_index(pa(keep),ga(keep),18);
r.mvl=pac_mean_vector_length(pa(keep),ga(keep));
[r.ppc,r.spike_phase]=spike_field_ppc(a,c.s,c.fs,2);
assert(numel(r.spike_phase)>=5,'battle:skip','Need >=5 interior spikes for circular tests.');
r.ppc_direct=pairwise_phase_consistency(r.spike_phase);
[r.mean_angle,r.resultant]=circular_mean(r.spike_phase);
r.rayleigh=rayleigh_test(r.spike_phase); % Analytic p assumes independent spikes.
[r.f,r.coherence]=coherence_spectrum(c.x,c.y,c.fs,2);
[r.f_mt,r.coherence_mt]=multitaper_coherence(c.x,c.y,c.fs,2,3,5);
[r.f_sf,r.spike_field]=spike_field_coherence(c.x,c.s,c.fs,2);
[r.wavelet,r.f_wavelet,r.time]=wavelet_coherence(c.x,c.y,c.fs,4:4:40,6,.5);
[r.psi,r.f_psi,r.coherency]=phase_slope_index(c.x,c.y,c.fs,[4 12],2);
% Circular-shift null: preserves amplitude series; choice of lag needs sensitivity.
r.pac_null=surrogate_test(ga(keep),@(z)modulation_index(pa(keep),z,18), ...
    @(z)circular_shift_surrogate(z,randi([round(c.fs),numel(z)-round(c.fs)])),cfg.draws,'right');

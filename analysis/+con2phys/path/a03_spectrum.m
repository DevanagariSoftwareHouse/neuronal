%% Spectral estimates and aperiodic sensitivity on one bounded real segment.
% Log-log slope is NOT full specparam; IRASA/BOSC are exploratory variants.
r=struct('mode','real');
[r.f,r.psd]=welch_psd(c.x,c.fs,2,.5);
[r.f_mt,r.psd_mt]=multitaper_psd(c.x,c.fs,3,5);
r.peaks=spectral_peak_candidates(r.f,r.psd,2,3);
r.slope=aperiodic_slope(r.f,r.psd,[2 100],[4 12;48 62]);
[r.f_irasa,r.fractal,r.oscillatory,r.total]=irasa_decomposition(c.x,c.fs,2,1.1:.2:1.9);
r.entropy=spectral_entropy(r.psd);
r.permutation_entropy=permutation_entropy(c.x,3,5);
if cfg.plots
    figure('Name','Spectra'); loglog(r.f,r.psd,r.f_mt,r.psd_mt,r.f_irasa,r.fractal);
    xlabel('Hz'); ylabel('Power / Hz'); legend('Welch','Multitaper','IRASA fractal');
end

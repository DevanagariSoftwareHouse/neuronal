%% Cluster statistics: counts are not proof of single-unit isolation.
r=struct('mode','real');
r.rate_hz=cellfun(@(s)firing_rate(s,0,c.duration),c.spikes);
r.isi=interspike_intervals(c.s);
r.refractory=spike_refractory_violations(c.s,.002);
r.presence=spike_presence_ratio(c.s,0,c.T,1);
[r.counts,r.centers,r.edges]=spike_bin_counts(c.s,0,c.T,.1);
r.explicit_counts=spike_counts_edges(c.s,r.edges);
assert(isequal(r.counts,r.explicit_counts));
[r.lags,r.auto]=autocorrelogram(c.s,0,c.T,.005,.2);
[~,r.cross]=crosscorrelogram(c.s,c.s2,0,c.T,.005,.2);
r.fano=spike_count_fano(c.C); % Across time bins, not repeated matched trials.
r.distance=victor_purpura_distance(c.s(c.s<2),c.s2(c.s2<2),10);
if cfg.plots
    figure('Name','Cluster statistics');
    subplot(1,2,1); histogram(r.isi,100); xlabel('ISI (s)');
    subplot(1,2,2); plot(r.lags,[r.auto r.cross]); xlabel('Lag (s)'); ylabel('Coincidences');
end

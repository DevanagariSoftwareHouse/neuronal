%% A02: CON2PHYS cluster timing-quality diagnostics (MATLAB R2019a+)
% Exploratory screening only: timestamps cannot establish single-unit isolation.
% Run this script with analysis/ on path. Output: cluster_quality table.
clc
clear
a00_startup
catalog = neuronal_catalog();

% Editable, diagnostic thresholds; NOT validated single-unit acceptance rules.
cfg.refractory_s = 0.002;    % 2 ms refractory-violation window
cfg.bins = 100;              % time bins for presence ratio
cfg.min_spikes_for_isi = 100;
cfg.max_viol_fraction = 0.01;
cfg.min_presence = 0.80;
% No firing-rate threshold: the outcome of interest is firing rate.

session = {};
cluster_id = int64([]);
brain_area = [];
spike_count = [];
firing_rate_hz = [];
isi_pairs = [];
refractory_violations = [];
refractory_fraction = [];
presence_ratio = [];
quality_flag = {};

for s = 1:numel(catalog.data)
    d = catalog.data(s);
    T = double(d.n_lfp_samples)/double(d.file(1).sampling_rate_hz);
    assert(isfinite(T) && T>0,'Invalid recording duration.');
    tsmap = neuronal_memmap(d.file(4),neuronal_path);
    idmap = neuronal_memmap(d.file(5),neuronal_path);
    t = double(tsmap.Data.x(:));
    labels = int64(idmap.Data.x(:));
    assert(numel(t)==numel(labels) && numel(t)==double(d.n_spikes), ...
        'Session %s spike arrays disagree with catalog.',d.id);
    assert(all(isfinite(t)), 'Nonfinite spike timestamps in session %s.',d.id);
    ids = int64(d.brain_areas.cluster_id(:));
    areas = double(d.brain_areas.brain_area(:));
    assert(numel(ids)==numel(areas) && numel(unique(ids))==numel(ids), ...
        'Invalid anatomical cluster mapping in %s.',d.id);

    for k = 1:numel(ids)
        st = sort(t(labels==ids(k) & t>=0 & t<T));
        N = numel(st);
        intervals = diff(st);
        n_isi = numel(intervals);
        n_viol = sum(intervals < cfg.refractory_s);
        if n_isi==0
            viol_frac = NaN;
        else
            viol_frac = n_viol/n_isi;
        end
        if N==0
            presence = 0;
        else
            occupied = unique(min(cfg.bins, floor(st/T*cfg.bins)+1));
            presence = numel(occupied)/cfg.bins;
        end
        % Very sparse units cannot be meaningfully screened via these metrics.
        if N < cfg.min_spikes_for_isi
            flag = 'insufficient_spikes';
        elseif viol_frac > cfg.max_viol_fraction
            flag = 'refractory_flag';
        elseif presence < cfg.min_presence
            flag = 'low_presence_flag';
        else
            flag = 'timing_screen_pass';
        end
        session{end+1,1} = d.id; %#ok<SAGROW>
        cluster_id(end+1,1) = ids(k); %#ok<SAGROW>
        brain_area(end+1,1) = areas(k); %#ok<SAGROW>
        spike_count(end+1,1) = N; %#ok<SAGROW>
        firing_rate_hz(end+1,1) = N/T; %#ok<SAGROW>
        isi_pairs(end+1,1) = n_isi; %#ok<SAGROW>
        refractory_violations(end+1,1) = n_viol; %#ok<SAGROW>
        refractory_fraction(end+1,1) = viol_frac; %#ok<SAGROW>
        presence_ratio(end+1,1) = presence; %#ok<SAGROW>
        quality_flag{end+1,1} = flag; %#ok<SAGROW>
    end
    fprintf('A02 session %s: %d catalog clusters checked.\n',d.id,numel(ids));
end

cluster_quality = table(session,cluster_id,brain_area,spike_count, ...
    firing_rate_hz,isi_pairs,refractory_violations, ...
    refractory_fraction,presence_ratio,quality_flag);
fprintf('A02: %d clusters; %d timing-screen passes. No single-unit claims.\n', ...
    height(cluster_quality),sum(strcmp(quality_flag,'timing_screen_pass')));
% Optional post-hoc sensitivity: filter cluster_quality, then compare area
% means; never interpret timing_screen_pass as validated single-unit status.

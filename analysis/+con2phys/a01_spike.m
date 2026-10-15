%% A01: CON2PHYS spike clusters and trial-based firing-rate uncertainty
% Run from MATLAB with analysis/ on the path. No figures or pauses.
clc
clear
a00_startup
catalog = neuronal_catalog();
n_boot = 1000;
alpha = 0.05;
rng(42,'twister'); % Reproducible trial bootstrap.

results = cell(numel(catalog.data),1);
for d = 1:numel(catalog.data)
    data = catalog.data(d);
    spike_map = neuronal_memmap(data.file(4),neuronal_path);
    cluster_map = neuronal_memmap(data.file(5),neuronal_path);
    spikeTimes = double(spike_map.Data.x(:));
    spikeClusters = cluster_map.Data.x(:);
    assert(numel(spikeTimes)==numel(spikeClusters) && ...
        numel(spikeTimes)==double(data.n_spikes), ...
        'Session %d spike arrays disagree with catalog.',d);

    fs = double(data.file(1).sampling_rate_hz);
    duration = double(data.n_lfp_samples)/fs;
    assert(isfinite(duration) && duration>0,'Invalid recording duration.');
    assert(all(isfinite(spikeTimes)),'Nonfinite spike timestamps.');
    % Mapping is from catalog metadata, not an assertion of single-unit quality.
    cluster_id = data.brain_areas.cluster_id(:);
    brain_area = data.brain_areas.brain_area(:);
    assert(numel(brain_area)==numel(cluster_id), ...
        'Brain area and cluster ID counts differ in session %d.',d);
    assert(numel(unique(cluster_id))==numel(cluster_id), ...
        'Duplicate cluster IDs in session %d.',d);

    % Full-recording rate: exclude spikes outside [0,duration).
    valid_time = spikeTimes>=0 & spikeTimes<duration;
    [tf,idx] = ismember(spikeClusters(valid_time),cluster_id);
    counts_all = accumarray(idx(tf),1,[numel(cluster_id),1],@sum,0);
    rate_all = counts_all/duration;

    tr = data.behavior.trials;
    t0 = double([tr.trial_start]');
    t1 = double([tr.trial_end]');
    good = isfinite(t0)&isfinite(t1)&t0>=0&t1<=duration&t1>t0;
    trial_index = find(good);
    t0=t0(good); t1=t1(good);
    trial_duration = t1-t0;
    ntrial=numel(t0);
    trial_counts = zeros(numel(cluster_id),ntrial);

    if ntrial>0
        [edges,~,bi]=unique([t0;t1]);
        first=bi(1:ntrial);
        last=bi(ntrial+1:end);
        for k=1:numel(cluster_id)
            st=spikeTimes(spikeClusters==cluster_id(k) & valid_time);
            st=st(st>=edges(1) & st<edges(end));
            bins=histcounts(st,edges);
            cumulative=[0,cumsum(bins)];
            trial_counts(k,:)=reshape(cumulative(last)-cumulative(first),1,[]);
        end
    end
    trial_rate = bsxfun(@rdivide,trial_counts,trial_duration');
    ci = NaN(numel(cluster_id),2);
    rate_trial = NaN(numel(cluster_id),1);
    if ntrial>0
        % Duration-weighted observed trial rate; trial-resampling percentile CI.
        rate_trial=sum(trial_counts,2)/sum(trial_duration);
        if ntrial>=2
            boot_rate=zeros(numel(cluster_id),n_boot);
            for b=1:n_boot
                draw=randi(ntrial,[1,ntrial]);
                boot_rate(:,b)=sum(trial_counts(:,draw),2)/sum(trial_duration(draw));
            end
            boot_rate=sort(boot_rate,2);
            low=max(1,ceil((alpha/2)*n_boot));
            high=min(n_boot,ceil((1-alpha/2)*n_boot));
            ci=[boot_rate(:,low),boot_rate(:,high)];
        end
    end

    results{d}=struct('session',data.id,'cluster_id',cluster_id, ...
        'brain_area',brain_area, ...
        'full_count',counts_all,'full_rate_hz',rate_all, ...
        'trial_index',trial_index,'trial_counts',trial_counts, ...
        'trial_duration_s',trial_duration,'trial_rate_hz',trial_rate, ...
        'trial_pooled_rate_hz',rate_trial,'trial_ci95_hz',ci, ...
        'unmapped_spikes',sum(~tf),'n_valid_trials',ntrial);
    fprintf('Session %s: %d mapped clusters, %d valid trials, min full rate %.6g Hz\n', ...
        data.id,numel(cluster_id),ntrial,min(rate_all));
end
fprintf('A01 complete: %d sessions. CI = 95%% trial-bootstrap percentile interval.\n',numel(results));

%% Lowest complete-recording rate in each anatomical area, across sessions.
all_area = vertcat(results{:});
area_codes = vertcat(all_area.brain_area);
all_rates = vertcat(all_area.full_rate_hz);
all_ids = vertcat(all_area.cluster_id);
all_sessions = cell(numel(all_rates),1);
pos = 1;
for d = 1:numel(results)
    n = numel(results{d}.cluster_id);
    all_sessions(pos:pos+n-1) = {results{d}.session};
    pos = pos+n;
end
fprintf('\nLowest complete-recording firing rate by brain area:\n');
for a = unique(area_codes(:))'
    ix = find(area_codes==a);
    [lowest,j] = min(all_rates(ix));
    k = ix(j);
    fprintf('Area %g: %.6g Hz (session %s, cluster %g)\n', ...
        double(a),lowest,all_sessions{k},double(all_ids(k)));
end

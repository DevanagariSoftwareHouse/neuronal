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
    spikeClusters = int64(cluster_map.Data.x(:));
    assert(numel(spikeTimes)==numel(spikeClusters) && ...
        numel(spikeTimes)==double(data.n_spikes), ...
        'Session %d spike arrays disagree with catalog.',d);

    fs = double(data.file(1).sampling_rate_hz);
    duration = double(data.n_lfp_samples)/fs;
    assert(isfinite(duration) && duration>0,'Invalid recording duration.');
    assert(all(isfinite(spikeTimes)),'Nonfinite spike timestamps.');
    % Mapping is from catalog metadata, not an assertion of single-unit quality.
    cluster_id = int64(data.brain_areas.cluster_id(:));
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

%% Population mean firing rate by anatomical area (mapped clusters).
% One rate per mapped cluster; clusters are nested within recording/animal.
% Bootstrap resamples animals first, then clusters within each sampled
% animal. This estimates population-mean uncertainty, not uncertainty in a
% single neuron's Poisson count. No quality-based unit filtering is implied.
all_area = [];
for d = 1:numel(results)
    all_area = [all_area; results{d}.brain_area(:)]; %#ok<AGROW>
end
area_codes = unique(all_area);
n_area = numel(area_codes);
area_mean = NaN(n_area,1);
area_ci95 = NaN(n_area,2);
area_ncluster = zeros(n_area,1);
area_nanimal = zeros(n_area,1);
area_sample = cell(n_area,1);

for ai = 1:n_area
    area = area_codes(ai);
    rates_by_animal = cell(numel(results),1);
    for d = 1:numel(results)
        selected = results{d}.brain_area == area;
        rates_by_animal{d} = results{d}.full_rate_hz(selected);
    end
    contributes = find(~cellfun(@isempty,rates_by_animal));
    per_animal = rates_by_animal(contributes);
    area_nanimal(ai) = numel(contributes);
    area_ncluster(ai) = sum(cellfun(@numel,per_animal));
    if area_ncluster(ai)==0, continue; end
    observed = vertcat(per_animal{:});
    area_mean(ai) = mean(observed); % cluster-weighted pooled mean
    area_sample{ai} = observed;
    if area_nanimal(ai)<2, continue; end
    estimates = zeros(n_boot,1);
    for b = 1:n_boot
        animals = randi(area_nanimal(ai),area_nanimal(ai),1);
        sum_rate = 0;
        n_unit = 0;
        for j = 1:numel(animals)
            values = per_animal{animals(j)};
            draw = randi(numel(values),numel(values),1);
            sum_rate = sum_rate + sum(values(draw));
            n_unit = n_unit + numel(draw);
        end
        estimates(b) = sum_rate/n_unit;
    end
    estimates = sort(estimates);
    lo = max(1,ceil((alpha/2)*n_boot));
    hi = min(n_boot,ceil((1-alpha/2)*n_boot));
    area_ci95(ai,:) = [estimates(lo), estimates(hi)];
end

area_summary = table(area_codes,area_ncluster,area_nanimal,area_mean, ...
    area_ci95(:,1),area_ci95(:,2), ...
    'VariableNames',{'brain_area','n_clusters','n_animals', ...
    'mean_rate_hz','ci95_low_hz','ci95_high_hz'});
disp(area_summary);
[~,lowest_area_row] = min(area_mean);
fprintf('Lowest population mean: brain area %g, %.6g Hz; 95%% hierarchical bootstrap CI [%.6g, %.6g] Hz.\n', ...
    double(area_codes(lowest_area_row)),area_mean(lowest_area_row), ...
    area_ci95(lowest_area_row,1),area_ci95(lowest_area_row,2));

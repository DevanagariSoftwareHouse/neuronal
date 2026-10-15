%% A05: Compare cluster-weighted and animal-weighted brain-area rates.
% A02 creates cluster_quality; screen labels are exploratory, not proof of
% isolated neurons. Animal-weighted means give each animal equal influence.
con2phys.a02_cluster_quality
rng(45,'twister');
n_boot = 2000;
alpha = 0.05;
areas = unique(cluster_quality.brain_area);
animals = unique(cluster_quality.session);
n_animals = numel(animals);
pass = strcmp(cluster_quality.quality_flag,'timing_screen_pass');

selection = {};
brain_area = [];
weighting = {};
n_clusters = [];
n_contributing_animals = [];
mean_rate_hz = [];
ci95_low_hz = [];
ci95_high_hz = [];

for scenario = 1:2
    if scenario==1
        included = true(height(cluster_quality),1);
        scenario_name = 'all_mapped';
    else
        included = pass;
        scenario_name = 'timing_screen_pass';
    end
    for ai = 1:numel(areas)
        mask = included & cluster_quality.brain_area==areas(ai);
        per_animal = cell(n_animals,1);
        for j = 1:n_animals
            keep = mask & strcmp(cluster_quality.session,animals{j});
            per_animal{j} = cluster_quality.firing_rate_hz(keep);
        end
        participating = find(~cellfun(@isempty,per_animal));
        groups = per_animal(participating);
        n_group = numel(groups);
        if n_group==0, continue; end
        observed = vertcat(groups{:});
        animal_means = cellfun(@mean,groups);
        for mode = 1:2
            if mode==1
                name = 'cluster_weighted';
                estimate = mean(observed);
            else
                name = 'animal_weighted';
                estimate = mean(animal_means);
            end
            ci = [NaN NaN];
            if n_group>=2
                draws = zeros(n_boot,1);
                for b = 1:n_boot
                    sampled_animals = randi(n_group,n_group,1);
                    b_means = zeros(n_group,1);
                    b_sums = zeros(n_group,1);
                    b_counts = zeros(n_group,1);
                    for k = 1:n_group
                        values = groups{sampled_animals(k)};
                        sampled_units = values(randi(numel(values),numel(values),1));
                        b_means(k) = mean(sampled_units);
                        b_sums(k) = sum(sampled_units);
                        b_counts(k) = numel(sampled_units);
                    end
                    if mode==1
                        draws(b) = sum(b_sums)/sum(b_counts);
                    else
                        draws(b) = mean(b_means);
                    end
                end
                draws = sort(draws);
                ci = [draws(max(1,ceil(alpha/2*n_boot))), ...
                      draws(min(n_boot,ceil((1-alpha/2)*n_boot)))];
            end
            selection{end+1,1} = scenario_name; %#ok<SAGROW>
            brain_area(end+1,1) = areas(ai); %#ok<SAGROW>
            weighting{end+1,1} = name; %#ok<SAGROW>
            n_clusters(end+1,1) = numel(observed); %#ok<SAGROW>
            n_contributing_animals(end+1,1) = n_group; %#ok<SAGROW>
            mean_rate_hz(end+1,1) = estimate; %#ok<SAGROW>
            ci95_low_hz(end+1,1) = ci(1); %#ok<SAGROW>
            ci95_high_hz(end+1,1) = ci(2); %#ok<SAGROW>
        end
    end
end
area_weighting = table(selection,brain_area,weighting,n_clusters, ...
    n_contributing_animals,mean_rate_hz,ci95_low_hz,ci95_high_hz);
disp(area_weighting);
for scenario = 1:2
    if scenario==1, label='all_mapped'; else, label='timing_screen_pass'; end
    for mode = 1:2
        if mode==1, name='cluster_weighted'; else, name='animal_weighted'; end
        idx = find(strcmp(selection,label) & strcmp(weighting,name));
        [best,j] = min(mean_rate_hz(idx));
        fprintf('%s / %s: lowest area %g (%.6g Hz)\n', ...
            label,name,brain_area(idx(j)),best);
    end
end
fprintf('A05 complete. Bootstrap CIs are unadjusted; timing flags may select on firing rate.\n');

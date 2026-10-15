%% A04: Paired hierarchical bootstrap of between-area rate differences.
% Runs A02 to compute timing screening. No single-unit identity claims.
% Animals are paired: each bootstrap replicate resamples the same animals
% for all brain areas; clusters are resampled within each selected animal.
a02_cluster_quality
rng(44,'twister');
n_boot = 2000;
alpha = 0.05;
areas = unique(cluster_quality.brain_area);
assert(all(ismember([1;2;3],areas)),'Expected area codes 1, 2, and 3.');
animal_ids = unique(cluster_quality.session);
n_animals = numel(animal_ids);
assert(n_animals>=2,'Need at least two animals.');
screen_pass = strcmp(cluster_quality.quality_flag,'timing_screen_pass');
pair_names = {'area2_minus_area1';'area2_minus_area3'};
selection = cell(4,1);
comparison = cell(4,1);
difference_hz = NaN(4,1);
ci95_low_hz = NaN(4,1);
ci95_high_hz = NaN(4,1);
probability_negative = NaN(4,1);
n_paired_animals = zeros(4,1);
for scenario = 1:2
    if scenario==1
        included = true(height(cluster_quality),1);
        label = 'all_mapped';
    else
        included = screen_pass;
        label = 'timing_screen_pass';
    end
    % One cell of cluster rates for each animal and area.
    cell_rates = cell(n_animals,3);
    for j = 1:n_animals
        in_animal = strcmp(cluster_quality.session,animal_ids{j});
        for ai = 1:3
            mask = included & in_animal & cluster_quality.brain_area==ai;
            cell_rates{j,ai} = cluster_quality.firing_rate_hz(mask);
        end
    end
    % Retain animals represented in all areas to keep comparisons paired.
    eligible = find(all(~cellfun(@isempty,cell_rates),2));
    n_eligible = numel(eligible);
    assert(n_eligible>=2,'Not enough paired animals for %s.',label);
    observed_sum = zeros(1,3);
    observed_n = zeros(1,3);
    for j = eligible'
        for ai = 1:3
            v = cell_rates{j,ai};
            observed_sum(ai) = observed_sum(ai)+sum(v);
            observed_n(ai) = observed_n(ai)+numel(v);
        end
    end
    observed_mean = observed_sum./observed_n;
    observed_diff = [observed_mean(2)-observed_mean(1), ...
                     observed_mean(2)-observed_mean(3)];
    bootstrap_diff = zeros(n_boot,2);
    for b = 1:n_boot
        draw = eligible(randi(n_eligible,n_eligible,1));
        totals = zeros(1,3);
        counts = zeros(1,3);
        for j = draw'
            for ai = 1:3
                v = cell_rates{j,ai};
                sampled = v(randi(numel(v),numel(v),1));
                totals(ai) = totals(ai)+sum(sampled);
                counts(ai) = counts(ai)+numel(sampled);
            end
        end
        mu = totals./counts;
        bootstrap_diff(b,:) = [mu(2)-mu(1), mu(2)-mu(3)];
    end
    for k = 1:2
        row = (scenario-1)*2+k;
        ordered = sort(bootstrap_diff(:,k));
        selection{row} = label;
        comparison{row} = pair_names{k};
        difference_hz(row) = observed_diff(k);
        ci95_low_hz(row) = ordered(max(1,ceil(alpha/2*n_boot)));
        ci95_high_hz(row) = ordered(min(n_boot,ceil((1-alpha/2)*n_boot)));
        probability_negative(row) = mean(bootstrap_diff(:,k)<0);
        n_paired_animals(row) = n_eligible;
    end
end
area_pairwise = table(selection,comparison,n_paired_animals,difference_hz, ...
    ci95_low_hz,ci95_high_hz,probability_negative);
disp(area_pairwise);
fprintf('A04: paired animal/cluster bootstrap finished. Intervals are descriptive bootstrap CIs; probability_negative is the fraction of resamples below zero, not a p-value.\n');

%% A03: Brain-area firing-rate sensitivity to A02 timing-screen selection.
% Uses A02 diagnostic labels, NOT validated single-unit classifications.
% A02 clears the workspace; run it first, then construct comparisons here.
a02_cluster_quality
rng(43,'twister');
n_boot = 1000;
alpha = 0.05;
areas = unique(cluster_quality.brain_area);
n_area = numel(areas);
n_scenarios = 2;
summary_area = zeros(n_area*n_scenarios,1);
scenario = cell(n_area*n_scenarios,1);
n_clusters = zeros(n_area*n_scenarios,1);
n_animals = zeros(n_area*n_scenarios,1);
mean_rate_hz = NaN(n_area*n_scenarios,1);
ci95_low_hz = NaN(n_area*n_scenarios,1);
ci95_high_hz = NaN(n_area*n_scenarios,1);
n_removed = zeros(n_area*n_scenarios,1);
screen_pass = strcmp(cluster_quality.quality_flag,'timing_screen_pass');
fprintf('\nA03: A02 exclusion counts by area (diagnostic only):\n');
for ai = 1:n_area
    ia = cluster_quality.brain_area == areas(ai);
    fprintf('Area %g: %d total, %d pass, %d flagged\n', ...
        areas(ai),sum(ia),sum(ia & screen_pass),sum(ia & ~screen_pass));
end

for si = 1:n_scenarios
    if si==1
        selected = true(height(cluster_quality),1);
        selection_name = 'all_mapped';
    else
        selected = screen_pass;
        selection_name = 'timing_screen_pass';
    end
    for ai = 1:n_area
        row = (si-1)*n_area + ai;
        ia = cluster_quality.brain_area == areas(ai);
        keep = ia & selected;
        summary_area(row) = areas(ai);
        scenario{row} = selection_name;
        n_clusters(row) = sum(keep);
        n_removed(row) = sum(ia)-n_clusters(row);
        if ~any(keep), continue; end
        values = cluster_quality.firing_rate_hz(keep);
        sessions = cluster_quality.session(keep);
        mean_rate_hz(row) = mean(values); % Each mapped cluster has equal weight.
        [animal_labels,~,animal_index] = unique(sessions);
        n_animals(row) = numel(animal_labels);
        if n_animals(row)<2, continue; end
        groups = cell(n_animals(row),1);
        for j = 1:n_animals(row)
            groups{j} = values(animal_index==j);
        end
        boot = zeros(n_boot,1);
        for b = 1:n_boot
            animal_draw = randi(n_animals(row),n_animals(row),1);
            summed = 0;
            total = 0;
            for j = 1:numel(animal_draw)
                v = groups{animal_draw(j)};
                picks = randi(numel(v),numel(v),1);
                summed = summed + sum(v(picks));
                total = total + numel(picks);
            end
            boot(b) = summed/total;
        end
        boot = sort(boot);
        ci95_low_hz(row) = boot(max(1,ceil(alpha/2*n_boot)));
        ci95_high_hz(row) = boot(min(n_boot,ceil((1-alpha/2)*n_boot)));
    end
end

area_sensitivity = table(scenario,summary_area,n_clusters,n_removed,n_animals, ...
    mean_rate_hz,ci95_low_hz,ci95_high_hz, ...
    'VariableNames',{'selection','brain_area','n_clusters','n_removed', ...
    'n_animals','mean_rate_hz','ci95_low_hz','ci95_high_hz'});
disp(area_sensitivity);
for si = 1:n_scenarios
    ix = (si-1)*n_area+(1:n_area);
    [best,k] = min(mean_rate_hz(ix));
    fprintf('%s: lowest population mean is area %g (%.6g Hz)\n', ...
        scenario{ix(1)},summary_area(ix(k)),best);
end
fprintf('Caution: A02 presence and spike-count flags depend on rate; screening can introduce selection bias.\n');

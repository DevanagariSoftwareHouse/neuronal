%% A06: Animal-aware firing-rate DISTRIBUTION comparisons.
% A02 supplies diagnostic timing-screen flags; no validated single-unit claims.
% Pairwise whole-animal label swaps (not cluster-level shuffling) give a
% conditional randomization p-value IF area labels are exchangeable as
% entire within-animal cluster groups under the null. Interpret cautiously.
a02_cluster_quality
rng(46,'twister');
n_perm = 1999;
quantile_levels = [10 25 50 75 90];
animal_ids = unique(cluster_quality.session);
n_animals = numel(animal_ids);
pairs = [2 1; 2 3];
selection = cell(0,1);
comparison = cell(0,1);
scale = cell(0,1);
n_paired_animals = zeros(0,1);
energy_distance = zeros(0,1);
permutation_p = zeros(0,1);
quantile_selection = cell(0,1);
quantile_area = zeros(0,1);
quantile_scale = cell(0,1);
quantile10 = zeros(0,1);
quantile25 = zeros(0,1);
quantile50 = zeros(0,1);
quantile75 = zeros(0,1);
quantile90 = zeros(0,1);
quantile_animals = zeros(0,1);
pass = strcmp(cluster_quality.quality_flag,'timing_screen_pass');

for scenario = 1:2
    if scenario==1
        mask = true(height(cluster_quality),1);
        label = 'all_mapped';
    else
        mask = pass;
        label = 'timing_screen_pass';
    end
    for transform = 1:2
        if transform==1
            tname = 'raw_hz';
            rates = cluster_quality.firing_rate_hz;
        else
            tname = 'log1p_hz';
            rates = log1p(cluster_quality.firing_rate_hz);
        end
        % Per-animal quantiles (equal weighting across contributing animals).
        for area = 1:3
            q = NaN(n_animals,5);
            for j = 1:n_animals
                idx = mask & cluster_quality.brain_area==area & ...
                    strcmp(cluster_quality.session,animal_ids{j});
                v = rates(idx);
                if ~isempty(v), q(j,:) = prctile(v,quantile_levels); end
            end
            good = all(isfinite(q),2);
            if ~any(good), continue; end
            muq = mean(q(good,:),1);
            quantile_selection{end+1,1} = label; %#ok<SAGROW>
            quantile_area(end+1,1) = area; %#ok<SAGROW>
            quantile_scale{end+1,1} = tname; %#ok<SAGROW>
            quantile_animals(end+1,1) = sum(good); %#ok<SAGROW>
            quantile10(end+1,1) = muq(1); %#ok<SAGROW>
            quantile25(end+1,1) = muq(2); %#ok<SAGROW>
            quantile50(end+1,1) = muq(3); %#ok<SAGROW>
            quantile75(end+1,1) = muq(4); %#ok<SAGROW>
            quantile90(end+1,1) = muq(5); %#ok<SAGROW>
        end
        for pi = 1:size(pairs,1)
            a = pairs(pi,1); b = pairs(pi,2);
            % Compute paired animal empirical CDFs on a common support.
            blocks_a = cell(n_animals,1);
            blocks_b = cell(n_animals,1);
            eligible = false(n_animals,1);
            for j = 1:n_animals
                in_animal = strcmp(cluster_quality.session,animal_ids{j});
                blocks_a{j} = rates(mask & in_animal & cluster_quality.brain_area==a);
                blocks_b{j} = rates(mask & in_animal & cluster_quality.brain_area==b);
                eligible(j) = ~isempty(blocks_a{j}) && ~isempty(blocks_b{j});
            end
            ia = find(eligible);
            assert(numel(ia)>=2,'Insufficient paired animals for A06.');
            x = vertcat(blocks_a{ia});
            y = vertcat(blocks_b{ia});
            grid = unique([0; x; y]);
            assert(all(isfinite(grid)) && all(grid>=0),'Invalid firing rates.');
            widths = diff(grid);
            cdf_difference = zeros(numel(ia),numel(grid));
            for k = 1:numel(ia)
                va = blocks_a{ia(k)};
                vb = blocks_b{ia(k)};
                % CDF differences evaluated at each breakpoint.
                ca = sum(bsxfun(@ge,grid',va(:)),1)/numel(va);
                cb = sum(bsxfun(@ge,grid',vb(:)),1)/numel(vb);
                cdf_difference(k,:) = ca-cb;
            end
            observed_curve = mean(cdf_difference,1);
            observed_distance = 2*sum(widths'.*(observed_curve(1:end-1).^2));
            ge_count = 1; % +1 randomization correction
            for rep = 1:n_perm
                signs = 2*(rand(numel(ia),1)>=0.5)-1;
                shuffled_curve = (signs'*cdf_difference)/numel(ia);
                shuffled_distance = 2*sum(widths'.*(shuffled_curve(1:end-1).^2));
                ge_count = ge_count + (shuffled_distance >= observed_distance-1e-12);
            end
            selection{end+1,1} = label; %#ok<SAGROW>
            comparison{end+1,1} = sprintf('area%d_vs_area%d',a,b); %#ok<SAGROW>
            scale{end+1,1} = tname; %#ok<SAGROW>
            n_paired_animals(end+1,1) = numel(ia); %#ok<SAGROW>
            energy_distance(end+1,1) = observed_distance; %#ok<SAGROW>
            permutation_p(end+1,1) = ge_count/(n_perm+1); %#ok<SAGROW>
        end
    end
end

area_distribution_tests = table(selection,comparison,scale,n_paired_animals, ...
    energy_distance,permutation_p);
area_quantiles = table(quantile_selection,quantile_area,quantile_scale, ...
    quantile_animals,quantile10,quantile25,quantile50,quantile75,quantile90, ...
    'VariableNames',{'selection','brain_area','scale','n_animals', ...
    'q10','q25','q50','q75','q90'});
disp(area_distribution_tests);
disp(area_quantiles);
fprintf(['A06: energy distance from animal-averaged empirical CDFs, with ', ...
    'whole-animal paired label swaps. The permutation p-value assumes ', ...
    'exchangeability of whole area groups within animals; ', ...
    'quantiles are averages of per-animal quantiles, not pooled quantiles.\n']);

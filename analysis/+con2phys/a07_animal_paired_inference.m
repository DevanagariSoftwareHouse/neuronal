%% A07: Animal-level paired inference for CON2PHYS area firing rates.
% Biological replicate = animal/session (verify each session is a distinct animal).
% Exact sign-flip tests require symmetric/exchangeable paired differences
% under the null; sign tests additionally offer a median-direction check.
% Quality-screen flags are exploratory, not confirmed single units.
a02_cluster_quality
rng(47,'twister');
n_boot = 10000;
areas = [1 2 3];
animals = unique(cluster_quality.session);
n_animals = numel(animals);
pass = strcmp(cluster_quality.quality_flag,'timing_screen_pass');
comparison = cell(0,1); selection = cell(0,1); endpoint = cell(0,1);
n_pairs = zeros(0,1); n_negative = zeros(0,1); n_positive = zeros(0,1);
n_ties = zeros(0,1); effect_hz = zeros(0,1);
ci95_low_hz = zeros(0,1); ci95_high_hz = zeros(0,1);
signflip_p = zeros(0,1); sign_p = zeros(0,1);
holm_p = zeros(0,1);
animal_differences = cell(2,2,2); % scenario, endpoint, comparison

for scenario = 1:2
    if scenario==1
        selected = true(height(cluster_quality),1);
        label = 'all_mapped';
    else
        selected = pass;
        label = 'timing_screen_pass';
    end
    per_mean = NaN(n_animals,3);
    per_median = NaN(n_animals,3);
    for j = 1:n_animals
        animal = strcmp(cluster_quality.session,animals{j});
        for a = 1:3
            mask = selected & animal & cluster_quality.brain_area==areas(a);
            v = cluster_quality.firing_rate_hz(mask);
            if ~isempty(v)
                per_mean(j,a) = mean(v);
                per_median(j,a) = median(v);
            end
        end
    end
    for metric = 1:2
        if metric==1
            matrix = per_mean; metric_name = 'animal_mean';
        else
            matrix = per_median; metric_name = 'animal_median';
        end
        for pair = 1:2
            if pair==1, other = 1; else, other = 3; end
            valid = isfinite(matrix(:,2)) & isfinite(matrix(:,other));
            differences = matrix(valid,2)-matrix(valid,other);
            animal_differences{scenario,metric,pair} = differences;
            n = numel(differences);
            assert(n>=2 && n<=20,'Exact enumeration requires 2-20 paired animals.');
            obs = mean(differences);
            % Two-sided exact sign-flip on the average paired difference.
            % Exclude zero differences from enumeration to save computation.
            dz = differences(differences~=0);
            nz = numel(dz);
            total = 2^nz;
            extreme = 0;
            chunk = 8192;
            for first = 0:chunk:total-1
                last = min(total-1,first+chunk-1);
                code = uint32((first:last)');
                bits = false(numel(code),nz);
                for k = 1:nz
                    bits(:,k) = bitget(code,k)>0;
                end
                sampled = (2*double(bits)-1)*dz/n;
                extreme = extreme + sum(abs(sampled)>=abs(obs)-1e-12);
            end
            pflip = extreme/total;
            % Exact two-sided sign test: does either sign dominate?
            negatives = sum(differences<0);
            positives = sum(differences>0);
            active = negatives+positives;
            if active==0
                psign = 1;
            else
                minor = min(negatives,positives);
                psign = min(1,2*sum(arrayfun(@(k)nchoosek(active,k),0:minor))/2^active);
            end
            % Animal bootstrap: observations are paired differences,
            % rather than individual clusters. Percentile CI for mean.
            draws = randi(n,n_boot,n);
            sampled_means = mean(differences(draws),2);
            ci = prctile(sampled_means,[2.5 97.5]);
            selection{end+1,1} = label; %#ok<SAGROW>
            endpoint{end+1,1} = metric_name; %#ok<SAGROW>
            comparison{end+1,1} = sprintf('area2_minus_area%d',other); %#ok<SAGROW>
            n_pairs(end+1,1) = n; %#ok<SAGROW>
            n_negative(end+1,1) = negatives; %#ok<SAGROW>
            n_positive(end+1,1) = positives; %#ok<SAGROW>
            n_ties(end+1,1) = n-active; %#ok<SAGROW>
            effect_hz(end+1,1) = obs; %#ok<SAGROW>
            ci95_low_hz(end+1,1) = ci(1); %#ok<SAGROW>
            ci95_high_hz(end+1,1) = ci(2); %#ok<SAGROW>
            signflip_p(end+1,1) = pflip; %#ok<SAGROW>
            sign_p(end+1,1) = psign; %#ok<SAGROW>
        end
    end
end
% Holm adjustment of the TWO planned area comparisons within each
% scenario and endpoint. Exploratory scenarios/endpoints remain distinct.
holm_p = NaN(size(signflip_p));
for s = 1:2
    for m = 1:2
        idx = (s-1)*4+(m-1)*2+(1:2);
        [p,order] = sort(signflip_p(idx));
        adjusted = min(1,[2*p(1);max(2*p(1),p(2))]);
        holm_p(idx(order)) = adjusted;
    end
end
area_paired_inference = table(selection,endpoint,comparison,n_pairs, ...
    n_negative,n_positive,n_ties,effect_hz,ci95_low_hz,ci95_high_hz, ...
    signflip_p,holm_p,sign_p);
disp(area_paired_inference);
fprintf(['A07 complete. Effect is average within-animal difference (Hz). ', ...
    'Exact sign-flip assumes paired-difference sign symmetry; ', ...
    'sign test probes direction and ignores ties. Bootstrap CIs are ', ...
    'animal-level. Holm correction is within each scenario/endpoint.\n']);

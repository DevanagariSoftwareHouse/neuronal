%% b01_bootstrap_firing_rate_area.m
% Requires data(d).waveform_id, data(d).waveform_area,
% data(d).spike_cluster.Data.x, data(d).n_lfp_samples.
% Primary estimand: equal-session-weight paired area mean difference.
% Sessions, not individual units, are independent sampling clusters.
run analysis/a00_startup.m
%%
B = 50000;
seed = 42;
lfp_srate = 500;
rng(seed, 'twister');

n_sessions = numel(data);
area_id    = [1 2 3];
n_area     = numel(area_id);
counts     = zeros(n_sessions, n_area);

session_mean = nan(n_sessions, n_area);
rate_cell    = cell(n_sessions, n_area);

session_col  = cell(n_sessions, 1);
area_col     = cell(n_sessions, 1);
rate_col     = cell(n_sessions, 1);

for d = 1:n_sessions
    duration = double(data(d).n_lfp_samples) / lfp_srate;
    
    assert(isscalar(duration) && isfinite(duration) && duration > 0, ...
        'Invalid LFP duration in session %d', d);

    ids = double(data(d).waveform_id(:));
    areas = double(data(d).waveform_area(:));
    spikes = double(data(d).spike_cluster.Data.x(:));

    assert(numel(ids) == numel(areas), 'Misaligned metadata in session %d', d);
    assert(numel(unique(ids)) == numel(ids), 'Duplicate waveform IDs in session %d', d);

    [matched, loc] = ismember(spikes, ids);
    spike_counts = accumarray(loc(matched), 1, [numel(ids), 1], @sum, 0);
    rate = spike_counts / duration;

    data(d).duration        = duration;
    
    data(d).spike_count     = spike_counts;
    data(d).spike_frequency = rate;

    session_col{d} = repmat(d, numel(rate), 1);
    
    area_col{d} = areas;
    rate_col{d} = rate;

    for a = 1:n_area
        x = rate(areas == area_id(a));
        x = x(isfinite(x));
        rate_cell{d,a} = x;
        counts(d,a) = numel(x);
        if ~isempty(x)
            session_mean(d,a) = mean(x);
        end
    end
end

units = table(vertcat(session_col{:}), vertcat(area_col{:}), ...
    vertcat(rate_col{:}), 'VariableNames', {'Session','Area','FiringRate'});

%% Level 1: unit distributions (description, NOT iid confidence intervals)
unit_summary = table('Size', [n_area, 6], ...
    'VariableTypes', {'double','double','double','double','double','double'}, ...
    'VariableNames', {'Area','N_units','Mean_Hz','Median_Hz','SD_Hz','N_sessions'});
for a = 1:n_area
    x = units.FiringRate(units.Area == area_id(a));
    unit_summary{a,:} = [area_id(a), numel(x), mean(x), median(x), ...
        std(x), sum(counts(:,a) > 0)];
end

disp('Unit-level descriptive summary:');
disp(unit_summary);

%% Level 2: session-level means (each session gets equal weight)
session_summary = table((1:n_sessions)', counts(:,1), counts(:,2), counts(:,3), ...
    session_mean(:,1), session_mean(:,2), session_mean(:,3), ...
    'VariableNames', {'Session','N1','N2','N3','Mean1','Mean2','Mean3'});
disp('Session-level summary:');
disp(session_summary);

%% Pairwise complete-session contrasts, with two bootstrap variants
pairs = [1 2; 1 3; 2 3];
contrast = nan(size(pairs,1), 9);
% Columns: AreaA AreaB N_sessions Difference_Hz CI_session_low
% CI_session_high CI_hier_low CI_hier_high Unit_pooled_diff_Hz
boot = struct();

for p = 1:size(pairs,1)
    a = pairs(p,1);
    b = pairs(p,2);
    eligible = find(counts(:,a) > 0 & counts(:,b) > 0);
    n = numel(eligible);

    if n < 2
        warning('Areas %d-%d: fewer than two matched sessions', a, b);
        contrast(p,1:3) = [a b n];
        continue
    end

    observed = mean(session_mean(eligible,a) - session_mean(eligible,b));
    draws_session = nan(B,1);
    draws_hier = nan(B,1);

    for k = 1:B
        % Resample the same sessions for both areas: preserves pairing.
        sampled = eligible(randi(n, n, 1));
        draws_session(k) = mean(session_mean(sampled,a) - session_mean(sampled,b));

        % Secondary, nested resampling of units WITHIN each sampled session.
        nested_difference = nan(n,1);
        for t = 1:n
            d = sampled(t);
            xa = rate_cell{d,a};
            xb = rate_cell{d,b};
            ma = mean(xa(randi(numel(xa), numel(xa), 1)));
            mb = mean(xb(randi(numel(xb), numel(xb), 1)));
            nested_difference(t) = ma - mb;
        end
        draws_hier(k) = mean(nested_difference);
    end

    ci_session = prctile(draws_session, [2.5, 97.5]);
    ci_hier = prctile(draws_hier, [2.5, 97.5]);
    pooled_a = unit_summary.Mean_Hz(unit_summary.Area == a);
    pooled_b = unit_summary.Mean_Hz(unit_summary.Area == b);
    contrast(p,:) = [a b n observed ci_session ci_hier pooled_a-pooled_b];

    boot(p).areas = [a b];
    boot(p).sessions = eligible;
    boot(p).session_draws = draws_session;
    boot(p).hierarchical_draws = draws_hier;
end

contrasts = array2table(contrast, 'VariableNames', ...
    {'AreaA','AreaB','N_sessions','Difference_Hz', ...
    'CI_session_low','CI_session_high','CI_hier_low', ...
    'CI_hier_high','Unit_pooled_diff_Hz'});
disp('Paired session-level area contrasts (95% bootstrap percentile CI):');
disp(contrasts);

%% Plot observed paired session differences by contrast
figure('Name', 'Session-paired firing rate contrasts');
    
for p = 1:3
    %nexttile;
    eligible = find(counts(:,pairs(p,1)) > 0 & counts(:,pairs(p,2)) > 0);
    y = session_mean(eligible,pairs(p,1)) - session_mean(eligible,pairs(p,2));
    subplot(1, 3,p);
    plot(eligible, y, 'o', 'MarkerSize', 6);
    hold on;
    yline(0, '--');
    if ~isempty(y)
        yline(mean(y), '-', 'LineWidth', 1.5);
    end
    hold off; grid on;
    xlabel('Session'); ylabel('Paired mean difference (Hz)');
    title(sprintf('Area %d - Area %d', pairs(p,1), pairs(p,2)));
end
%%
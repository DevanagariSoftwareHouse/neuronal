%% t05: Reproducible descriptive visualizations from t04 summary tables.
% MATLAB R2019a. Run after t04, without loading original HDF5 artifacts.
% The frequency intervals overlap; each level is plotted separately.

repo_root = fileparts(fileparts(mfilename('fullpath')));

cfg = struct();
cfg.run_root                  = fullfile(repo_root,'data','derived','spike_lfp_intervals', ...
    'tpf41d1e7f_71a8_4aaf_a0d4_5f43779e008b');
cfg.session_key               = 'session_01';
cfg.image_resolution          = 160;           % DPI
cfg.target_phase_hz           = 8;             % example preferred-phase band

stats_dir = fullfile(cfg.run_root,'statistics',cfg.session_key);
stats_file = fullfile(stats_dir,'band_statistics.mat');
assert(isfile(stats_file),'Run t04_spike_lfp_statistics.m first.');
source = load(stats_file,'band_statistics','frequency_table','analysis_settings');
tab = source.band_statistics;
freq = source.frequency_table;
levels = unique(freq(:,4))';
centers = (freq(:,2)+freq(:,3))/2;
areas = unique(tab.area,'stable');
fig_dir = fullfile(stats_dir,'figures');
if ~isfolder(fig_dir), mkdir(fig_dir); end

% A. Per-area channel-by-frequency maps: PPC, PLV and eligibility.
fields = {'mean_ppc','mean_plv','eligible_fraction'};
labels = {'Mean neuron-level PPC','Mean neuron-level PLV', ...
    'Fraction of neurons with eligible phase counts'};
for ai = 1:numel(areas)
    area = areas{ai};
    selected = strcmp(tab.area,area);
    a = tab(selected,:);
    channels = unique(a.channel);
    for metric = 1:numel(fields)
        M = nan(numel(channels),size(freq,1));
        for k = 1:height(a)
            j = find(channels == a.channel(k),1);
            fi = find(freq(:,1) == a.frequency_id(k),1);
            if ~isempty(fi)
                M(j,fi) = a.(fields{metric})(k);
            end
        end
        fig = figure('Visible','off','Color','w','Position',[50 50 1400 520]);
        imagesc(1:size(freq,1),channels,M);
        set(gca,'YDir','normal');
        colormap(parula);
        if strcmp(fields{metric},'mean_ppc')
            caxis([-0.25 1]);
        else
            caxis([0 1]);
        end
        colorbar;
        xlabel('Frequency interval ID (multiresolution bank)');
        ylabel('LFP channel');
        title(sprintf('%s — %s',area,labels{metric}),'Interpreter','none');
        hold on;
        for li = 2:numel(levels)
            first = find(freq(:,4) == levels(li),1,'first');
            if ~isempty(first)
                plot([first-.5 first-.5],ylim,'k:','LineWidth',0.5);
            end
        end
        hold off;
        out = fullfile(fig_dir,sprintf('%s_%s.png',fields{metric},area));
        print(fig,out,'-dpng',sprintf('-r%d',cfg.image_resolution));
        close(fig);
    end
end

% B. Frequency profile. Median of channel-wise mean PPC, separated by
% dyadic frequency level; neither bands nor channels imply independence.
fig = figure('Visible','off','Color','w','Position',[50 50 1400 850]);
for ai = 1:numel(areas)
    area = areas{ai};
    a = tab(strcmp(tab.area,area),:);
    profile = nan(size(freq,1),1);
    for fi = 1:size(freq,1)
        x = a.mean_ppc(a.frequency_id == freq(fi,1));
        x = x(isfinite(x));
        if ~isempty(x), profile(fi) = median(x); end
    end
    subplot(numel(areas),1,ai);
    hold on;
    for li = 1:numel(levels)
        which = freq(:,4) == levels(li) & isfinite(profile);
        xx = centers(which); yy = profile(which);
        [xx,ix] = sort(xx);
        plot(xx,yy(ix),'.-','DisplayName',sprintf('Level %d',levels(li)));
    end
    hold off;
    ylim([-0.25 1]); xlim([0 max(freq(:,3))]);
    xlabel('Frequency-band center (Hz)');
    ylabel('Median channel PPC');
    title(sprintf('%s — channel-median neuron PPC',area),'Interpreter','none');
    legend('Location','eastoutside');
    grid on;
end
print(fig,fullfile(fig_dir,'ppc_frequency_profiles.png'),'-dpng', ...
    sprintf('-r%d',cfg.image_resolution));
close(fig);

% C. Illustrative polar preferred-phase distribution across channels at one
% narrow band near 8 Hz. This is descriptive, not evidence of significance.
positive = freq(:,2) > 0;
[~,order] = sort(abs(centers-cfg.target_phase_hz) ...
    + 0.01*(freq(:,3)-freq(:,2)) ...
    + 1000*(~positive));
selected_band = freq(order(1),1);
for ai = 1:numel(areas)
    area = areas{ai};
    a = tab(strcmp(tab.area,area) & tab.frequency_id == selected_band,:);
    ok = isfinite(a.pooled_phase_rad) & isfinite(a.pooled_plv);
    fig = figure('Visible','off','Color','w','Position',[50 50 600 500]);
    if any(ok)
        polarplot(a.pooled_phase_rad(ok),a.pooled_plv(ok),'o','MarkerSize',5);
        rlim([0 1]);
    else
        polarplot(NaN,NaN);
    end
    band = freq(freq(:,1) == selected_band,:);
    title(sprintf('%s: pooled phase by channel [%g, %g] Hz', ...
        area,band(2),band(3)),'Interpreter','none');
    out = fullfile(fig_dir,sprintf('pooled_phase_%s.png',area));
    print(fig,out,'-dpng',sprintf('-r%d',cfg.image_resolution));
    close(fig);
end

fprintf('t05 finished. Figures: %s\n',fig_dir);

%% t06: Multilevel temporal diagnostics for a representative band/channel.
% MATLAB R2019a. Unlike t04, this stage reads all temporal windows, but it
% does NOT treat overlapping windows as independent observations.

repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo_root,'matlab','path'));

cfg = struct();
cfg.run_root                  = fullfile(repo_root,'data','derived','spike_lfp_intervals', ...
    'tpf41d1e7f_71a8_4aaf_a0d4_5f43779e008b');
cfg.session_key               = 'session_01';
cfg.areas                     = {'lfp_1','lfp_2','lfp_3'};
cfg.channel                   = 1;
cfg.target_frequency_hz       = 8;
cfg.min_spikes_per_unit       = 10;
cfg.image_resolution          = 160;

st = storage_hdf5('root',cfg.run_root,'readonly',true);
wins = double(storage_read(st,[cfg.session_key '/windows']));
freq = double(storage_read(st,[cfg.session_key '/frequency_bands']));
meta = storage_info(st,[cfg.session_key '/windows']);
original_cfg = meta.metadata.cfg;
filter_name = sprintf('%s_order%d_%s',original_cfg.filter_method, ...
    original_cfg.filter_order,original_cfg.filter_phase);
center = (freq(:,2)+freq(:,3))/2;
[~,ix] = sort(abs(center-cfg.target_frequency_hz) ...
    + 0.01*(freq(:,3)-freq(:,2)) + 1000*(freq(:,2) == 0));
frequency_id = freq(ix(1),1);
output_dir = fullfile(cfg.run_root,'statistics',cfg.session_key,'figures');
if ~isfolder(output_dir), mkdir(output_dir); end

for ai = 1:numel(cfg.areas)
    area = cfg.areas{ai};
    key = storage_key('session',cfg.session_key(9:end),'area',area, ...
        'channel',cfg.channel,'frequency',frequency_id,'filter',filter_name);
    if ~storage_exists(st,[key '/complete'])
        warning('spike_lfp:MissingBand','Skipping incomplete band: %s',key);
        continue;
    end
    R = double(storage_read(st,[key '/phase_strength']));
    n = double(storage_read(st,[key '/phase_count']));
    assert(isequal(size(R),size(n)) && size(R,1) == size(wins,1), ...
        'Temporal summary dimensions do not match windows.');
    median_ppc = nan(size(wins,1),1);
    eligible_fraction = zeros(size(wins,1),1);
    for w = 1:size(wins,1)
        mask = n(w,:) >= cfg.min_spikes_per_unit & ...
            isfinite(R(w,:)) & R(w,:) >= 0 & R(w,:) <= 1+1e-5;
        eligible_fraction(w) = nnz(mask)/size(R,2);
        if any(mask)
            ppc = (n(w,mask).*min(1,R(w,mask)).^2-1)./(n(w,mask)-1);
            median_ppc(w) = median(ppc);
        end
    end
    levels = unique(wins(:,3))';
    tcenter = (wins(:,1)+wins(:,2))/2;
    fig = figure('Visible','off','Color','w','Position',[50 50 1200 750]);
    for metric = 1:2
        subplot(2,1,metric);
        hold on;
        for li = 1:numel(levels)
            chosen = wins(:,3) == levels(li);
            tt = tcenter(chosen);
            if metric == 1
                vv = median_ppc(chosen);
            else
                vv = eligible_fraction(chosen);
            end
            [tt,sort_idx] = sort(tt);
            plot(tt,vv(sort_idx),'.-','DisplayName',sprintf('Level %d',levels(li)));
        end
        hold off;
        xlabel('Time from session start (s)');
        if metric == 1
            ylabel('Median neuron-level PPC'); ylim([-0.25 1]);
        else
            ylabel('Fraction of eligible neurons'); ylim([0 1]);
        end
        grid on;
        legend('Location','eastoutside');
    end
    band = freq(freq(:,1) == frequency_id,:);
    subplot(2,1,1);
    title(sprintf('%s channel %d: temporal [%g, %g] Hz', ...
        area,cfg.channel,band(2),band(3)),'Interpreter','none');
    out = fullfile(output_dir,sprintf('temporal_%s_ch_%04d.png',area,cfg.channel));
    print(fig,out,'-dpng',sprintf('-r%d',cfg.image_resolution));
    close(fig);
end
fprintf('t06 finished. Temporal diagnostics: %s\n',output_dir);

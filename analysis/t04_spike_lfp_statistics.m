%% t04: Descriptive Spike/LFP statistics from completed t03 stores.
% MATLAB R2019a. No raw spike/LFP arrays, filtering, or GPU required.
% Run from the repository root. Edit cfg.run_root when changing runs.
% Only the unique full-session temporal window (level 0) is summarized;
% overlapping time windows are NOT treated as independent replications.

repo_root = fileparts(fileparts(mfilename('fullpath')));
repo_root = neuronal_dir
addpath(fullfile(repo_root,'matlab','path'));

cfg = struct();
cfg.run_root                  = fullfile(repo_root,'data','derived','spike_lfp_intervals', ...
    'tpf41d1e7f_71a8_4aaf_a0d4_5f43779e008b');
cfg.session_key               = 'session_01';
cfg.areas                     = {'lfp_1','lfp_2','lfp_3'};
cfg.min_spikes_per_unit       = 10;            % for each frequency/channel
cfg.strict_completion         = true;          % stop if any band marker is missing
cfg.write_csv                 = true;

assert(isfolder(cfg.run_root),'Run root not found: %s',cfg.run_root);
st = storage_hdf5('root',cfg.run_root,'readonly',true);

session_key = storage_key(cfg.session_key);
assert(storage_exists(st,[session_key '/complete']), ...
    'Session completion marker is absent. Audit the run before statistics.');
window_table    = double(storage_read(st,[session_key '/windows']));
frequency_table = double(storage_read(st,[session_key '/frequency_bands']));
spike_count     = storage_read(st,[session_key '/spike_count']);
window_meta     = storage_info(st,[session_key '/windows']);
original_cfg    = window_meta.metadata.cfg;
filter_label    = sprintf('%s_order%d_%s',original_cfg.filter_method, ...
    original_cfg.filter_order,original_cfg.filter_phase);

assert(size(window_table,2) >= 3 && size(frequency_table,2) >= 5, ...
    'Unexpected window or frequency table layout.');
full_rows = find(window_table(:,3) == 0);
assert(numel(full_rows) == 1,'Expected exactly one level-0 full-session window.');
window_row = full_rows(1);
assert(window_table(window_row,1) == 0 && ...
    all(window_table(window_row,2) >= window_table(:,2)), ...
    'Level-0 window does not span the full session.');
assert(size(spike_count,1) == size(window_table,1), ...
    'Spike count does not match time window rows.');

n_frequency = size(frequency_table,1);
channels_by_area = cell(numel(cfg.areas),1);
total_rows = 0;
for ai = 1:numel(cfg.areas)
    area = cfg.areas{ai};
    entries = dir(fullfile(st.root,'artifacts',session_key,area,'ch_*'));
    entries = entries([entries.isdir]);
    channel_ids = zeros(numel(entries),1);
    count = 0;
    for j = 1:numel(entries)
        token = regexp(entries(j).name,'^ch_([0-9]+)$','tokens','once');
        if isempty(token), continue; end
        count = count+1;
        channel_ids(count) = str2double(token{1});
    end
    channel_ids = sort(channel_ids(1:count));
    assert(numel(unique(channel_ids)) == numel(channel_ids), ...
        'Repeated channel ID in %s.',area);
    channels_by_area{ai} = channel_ids;
    total_rows = total_rows+n_frequency*numel(channel_ids);
end
assert(total_rows > 0,'No processed channels found.');

names = {'channel','frequency_id','low_hz','high_hz','level','overlap', ...
    'units_total','units_eligible','units_bad','spikes_valid','spikes_window', ...
    'exposure_seconds','phase_valid_fraction','eligible_fraction', ...
    'median_plv','mean_plv','median_ppc','mean_ppc', ...
    'pooled_plv','pooled_phase_rad','mean_amplitude','eligible_rate_hz'};
values = nan(total_rows,numel(names));
area_names = cell(total_rows,1);
missing_keys = cell(0,1);
timer = tic;
row = 0;

for ai = 1:numel(cfg.areas)
    area = cfg.areas{ai};
    channel_ids = channels_by_area{ai};
    for ci = 1:numel(channel_ids)
        ch = channel_ids(ci);
        for fi = 1:n_frequency
            row = row+1;
            area_names{row} = area;
            frequency_id = frequency_table(fi,1);
            assert(frequency_id == fix(frequency_id) && frequency_id > 0, ...
                'Invalid frequency ID.');
            values(row,1:6) = [ch frequency_table(fi,1:5)];
            key = storage_key('session',session_key(9:end),'area',area, ...
                'channel',ch,'frequency',frequency_id,'filter',filter_label);
            if ~storage_exists(st,[key '/complete'])
                missing_keys{end+1,1} = key; %#ok<SAGROW>
                if cfg.strict_completion
                    error('spike_lfp:MissingBand','Missing completion marker: %s',key);
                end
                continue;
            end
            phase_mean     = storage_read(st,[key '/phase_mean'],[window_row window_row]);
            phase_strength = storage_read(st,[key '/phase_strength'],[window_row window_row]);
            amplitude_mean = storage_read(st,[key '/amplitude_mean'],[window_row window_row]);
            phase_count    = storage_read(st,[key '/phase_count'],[window_row window_row]);
            exposure       = storage_read(st,[key '/phase_exposure_seconds'],[window_row window_row]);
            s = spike_lfp_summarize_band(phase_mean,phase_strength,amplitude_mean, ...
                phase_count,spike_count(window_row,:),exposure,cfg.min_spikes_per_unit);
            values(row,7:end) = [s.units_total s.units_eligible s.units_bad ...
                s.spikes_valid s.spikes_window s.exposure_seconds ...
                s.phase_valid_fraction s.eligible_fraction s.median_plv s.mean_plv ...
                s.median_ppc s.mean_ppc s.pooled_plv s.pooled_phase_rad ...
                s.mean_amplitude s.eligible_rate_hz];
        end
        fprintf('%s channel %02d: %d/%d frequencies inspected (%.1f s)\n', ...
            area,ch,n_frequency,n_frequency,toc(timer));
    end
end

band_statistics = [table(area_names,'VariableNames',{'area'}) ...
    array2table(values,'VariableNames',names)];
analysis_settings = struct('cfg',cfg,'window_row',window_row, ...
    'filter_label',filter_label,'created_at',datestr(now,30), ...
    'unit_of_replication','descriptive neurons; channels NOT independent subjects', ...
    'ppc_assumption','independent identically distributed event phases');
output_dir = fullfile(cfg.run_root,'statistics',session_key);
if ~isfolder(output_dir), mkdir(output_dir); end
stats_file = fullfile(output_dir,'band_statistics.mat');
save(stats_file,'band_statistics','frequency_table','window_table', ...
    'analysis_settings','missing_keys','-v7.3');
if cfg.write_csv
    writetable(band_statistics,fullfile(output_dir,'band_statistics.csv'));
end
fprintf('t04 completed in %.1f seconds. Wrote %d rows, %d missing markers.\n', ...
    toc(timer),height(band_statistics),numel(missing_keys));
fprintf('Output: %s\n',stats_file);

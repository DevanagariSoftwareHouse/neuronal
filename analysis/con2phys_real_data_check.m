% CON2PHYS_REAL_DATA_CHECK Validate complete-recording spike rates locally.
% Run: matlab-r2019a -batch "run('analysis/con2phys_real_data_check.m')"
% Optional: NEURONAL_CATALOG_PATH (catalog.mat), NEURONAL_DATA_ROOT
% (root containing data/raw/). Raw recordings never leave the runner.
repo = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo,'matlab','path'));
catalog_path = getenv('NEURONAL_CATALOG_PATH');
if isempty(catalog_path)
    catalog_path = fullfile(repo,'data','neuronal','catalog.mat');
end
data_root = getenv('NEURONAL_DATA_ROOT');
if isempty(data_root)
    data_root = repo;
end
assert(isfile(catalog_path),'CON2PHYS:CatalogMissing', ...
    'Catalog not found: %s. Set NEURONAL_CATALOG_PATH.',catalog_path);
catalog = neuronal_catalog(catalog_path);
assert(isfield(catalog,'data') && numel(catalog.data)==18, ...
    'CON2PHYS:Sessions','Expected exactly 18 sessions.');
fprintf('CON2PHYS real-data validation: %d sessions\n',numel(catalog.data));
for s = 1:numel(catalog.data)
    d = catalog.data(s);
    assert(numel(d.file)>=5,'CON2PHYS:Files','Session %d missing spike descriptors.',s);
    time_map = neuronal_memmap(d.file(4),data_root);
    cluster_map = neuronal_memmap(d.file(5),data_root);
    t = double(time_map.Data.x(:));
    ids = cluster_map.Data.x(:);
    assert(numel(t)==numel(ids) && numel(t)==double(d.n_spikes), ...
        'CON2PHYS:SpikeCount','Session %d: spike array sizes disagree.',s);
    assert(all(isfinite(t)),'CON2PHYS:Timestamp','Session %d: nonfinite timestamp.',s);
    assert(isfield(d,'file') && double(d.n_lfp_samples)>0, ...
        'CON2PHYS:Duration','Session %d: invalid LFP sample count.',s);
    fs = 500; % CON2PHYS LFP sampling rate, Hz
    if isfield(d.file(1),'sampling_rate_hz')
        fs = double(d.file(1).sampling_rate_hz);
    end
    assert(isscalar(fs) && isfinite(fs) && fs>0, ...
        'CON2PHYS:Sampling','Session %d: invalid sampling rate.',s);
    duration = double(d.n_lfp_samples)/fs;
    mapped = d.brain_areas.cluster_id(:);
    assert(numel(unique(mapped))==numel(mapped), ...
        'CON2PHYS:ClusterIds','Session %d: duplicate mapped cluster IDs.',s);
    [present,~,group] = unique(ids);
    n = accumarray(group,1,[numel(present),1]);
    [known,loc] = ismember(mapped,present);
    counts = zeros(numel(mapped),1);
    counts(known) = n(loc(known));
    rates = counts/duration;
    assert(all(isfinite(rates) & rates>=0), ...
        'CON2PHYS:Rates','Session %d: invalid cluster rates.',s);
    excluded = sum(~ismember(ids,mapped));
    fprintf('session %02d | spikes %d | mapped clusters %d | duration %.2f s | min rate %.6g Hz | unmapped spikes %d\n', ...
        s,numel(t),numel(mapped),duration,min(rates),excluded);
    clear time_map cluster_map t ids
end
fprintf('PASS: all 18 CON2PHYS recordings validated.\n');

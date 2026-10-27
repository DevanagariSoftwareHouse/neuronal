%% Disk-backed LFP window measurements (MATLAB R2019a).
% Run analysis/a00_startup.m first to construct data, then run this script.
% Optional cfg overrides are merged with defaults below. No session_windows
% load is needed. Temporal settings MUST match the spike-window producer.
% One CPU channel and one filter configuration are processed at a time.
% Each output file has top-level [window x configuration] numeric variables.
% Only columns whose completed flag is true may be read as valid results.
% Example:
%   cfg = struct('sessions',1,'channels',1,'time_levels',0:5);
%   run('analysis/+con2phys/t03_session_window_filter.m')
% Read later: m=matfile(file); x=m.mean_amplitude(1:100,2);
assert(exist('data','var') == 1, 'Run analysis/a00_startup.m first.');
if ~exist('cfg','var'), cfg = struct(); end
cfg.root = neuronal_dir;
cfg.output_dir = fullfile(neuronal_dir,'/data/derived/session_window_filter_v2')
cfg = swf_defaults(cfg);
swf_run(data, cfg);

function cfg = swf_defaults(cfg)
%%
%fileparts(fileparts(fileparts(mfilename('fullpath'))));
defaults = struct('root','.','sessions',1, 'areas',{{'lfp_1','lfp_2','lfp_3'}}, ...
    'channels',[], 'methods',{{'butterworth'}}, 'orders',4, ...
    'time_levels',0:15, 'time_overlap',0.5, ...
    'frequency_levels',0:7, 'frequency_overlap',0.5, ...
    'transition_fraction',0.2, 'phase','causal', ...
    'output_dir',fullfile(cfg.root,'data','derived','session_window_filter_v2'));
assert(isstruct(cfg) && isscalar(cfg), 'cfg must be a scalar struct.');
names = fieldnames(cfg);
assert(all(ismember(names,fieldnames(defaults))), ...
    'Unknown cfg field. Use separate time_levels and frequency_levels.');
names = fieldnames(defaults);
for k = 1:numel(names)
    if ~isfield(cfg,names{k}), cfg.(names{k}) = defaults.(names{k}); end
end
validateattributes(cfg.transition_fraction,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(cfg.orders,{'numeric'}, ...
    {'vector','nonempty','integer','positive','finite'});
assert(any(strcmp(cfg.phase,{'causal','zero'})), 'Invalid phase policy.');
assert(numel(unique(cfg.time_levels)) == numel(cfg.time_levels), ...
    'Temporal levels must be unique.');
end

function swf_run(data,cfg)
validateattributes(cfg.sessions,{'numeric'}, ...
    {'vector','nonempty','integer','>=',1,'<=',numel(data)});
if ~exist(cfg.output_dir,'dir'), mkdir(cfg.output_dir); end
% Record implementation text so resumed runs cannot silently mix versions.
code = struct('pipeline',fileread([mfilename('fullpath') '.m']));
dependencies = {'filter_design','filter_do','interval_dyadic', ...
    'interval_madic','interval_sliding','interval_session','interval_from_bounds'};
for k = 1:numel(dependencies)
    name = dependencies{k};
    code.(name) = fileread(which(name));
end
for dd = cfg.sessions(:)'
    d = data(dd); N = double(d.n_lfp_samples); Fs = double(d.srate);
    geometry = swf_geometry(N,Fs,cfg);
    catalog = swf_catalog(Fs,cfg);
    n_windows = numel(geometry.first); n_configs = numel(catalog);
    assert(n_windows > 0 && n_configs > 0, 'Empty window/configuration bank.');
    folder = fullfile(cfg.output_dir,['session_' char(d.id)]);
    if ~exist(folder,'dir'), mkdir(folder); end
    meta = struct('schema',2,'session_id',d.id,'N',N,'Fs',Fs, ...
        'time_levels',cfg.time_levels,'time_overlap',cfg.time_overlap, ...
        'phase',cfg.phase,'precision','double','code',code, ...
        'derivatives','backward differences assigned to later sample', ...
        'validity','no amplitude threshold or edge exclusion', ...
        'units',{{'input LFP units','rad/s','rad/s^2'}}, ...
        'matlab_version',version);
    geometry_path = fullfile(folder,'geometry.mat');
    catalog_path = fullfile(folder,'catalog.mat');
    geometry_payload = geometry;
    geometry_payload.meta = meta;
    swf_small_file(geometry_path,geometry_payload);
    swf_small_file(catalog_path,struct('catalog',catalog));
    fprintf('Session %s: %d windows, %d configurations, %.2f GiB/channel (uncompressed).\n', ...
        char(d.id),n_windows,n_configs,7*8*n_windows*n_configs/2^30);
    for a = 1:numel(cfg.areas)
        area = cfg.areas{a}; m = d.(area);
        % Inspect mapping metadata; do not materialize the entire LFP array.
        fmt = m.Format;
        assert(iscell(fmt) && size(fmt,1)==1 && strcmp(fmt{1,3},'x'), ...
            'Expected one numeric mapped field named x.');
        shape = fmt{1,2};
        assert(numel(shape)==2, 'Expected a two-dimensional LFP mapping.');
        sample_dim = find(shape == N);
        assert(isscalar(sample_dim), 'Cannot identify sample dimension uniquely.');
        n_channels = shape(3-sample_dim);
        channels = cfg.channels;
        if isempty(channels), channels = 1:n_channels; end
        validateattributes(channels,{'numeric'}, ...
            {'vector','integer','>=',1,'<=',n_channels});
        info = dir(m.Filename);
        assert(isscalar(info), 'Source file is missing or ambiguous.');
        source = struct('filename',m.Filename,'format',{fmt}, ...
            'offset',m.Offset,'repeat',m.Repeat, ...
            'bytes',info.bytes,'datenum',info.datenum);
        for ch = channels(:)'
            filename = fullfile(folder,sprintf('%s_ch%03d.mat',area,ch));
            channel_meta = struct('session',meta,'source',source, ...
                'area',area,'channel',ch,'catalog',catalog, ...
                'n_windows',n_windows,'n_configs',n_configs);
            swf_channel(filename,m,sample_dim,ch,Fs,geometry,catalog,channel_meta,cfg);
            fprintf('Saved %s\n',filename);
        end
    end
end
end

function g = swf_geometry(N,Fs,cfg)
counts = arrayfun(@(l) interval_dyadic(N,Fs,l,cfg.time_overlap),cfg.time_levels);
n = sum(counts);
g = struct('first',zeros(n,1),'last',zeros(n,1), ...
    'level',zeros(n,1),'window',zeros(n,1),'overlap',cfg.time_overlap);
row = 0;
for ll = 1:numel(cfg.time_levels)
    for w = 1:counts(ll)
        I = interval_dyadic(N,Fs,cfg.time_levels(ll),cfg.time_overlap,w);
        row = row+1;
        g.first(row) = I.first; g.last(row) = I.last;
        g.level(row) = cfg.time_levels(ll); g.window(row) = w;
    end
end
assert(all(g.first>=1 & g.last<=N & g.first<=g.last), 'Invalid geometry.');
end

function catalog = swf_catalog(Fs,cfg)
catalog = struct([]);
% Frequency intervals use normalized dyadic coordinates, scaled to Nyquist.
% 2^max(level) supplies enough nominal samples for interval validation.
validateattributes(cfg.frequency_levels,{'numeric'}, ...
    {'vector','nonempty','integer','nonnegative','finite','<=',30});
base = 2^max(cfg.frequency_levels);
for level = cfg.frequency_levels(:)'
    count = interval_dyadic(base,base,level,cfg.frequency_overlap);
    for w = 1:count
        I = interval_dyadic(base,base,level,cfg.frequency_overlap,w);
        band = [I.t0 I.t1]*(Fs/2);
        for nf = 1:numel(cfg.methods)
            method = cfg.methods{nf};
            for order = cfg.orders(:)'
                if any(strcmp(method,{'windowed_fir','equiripple_fir'})) && mod(order,2)
                    continue
                end
                args = {};
                if strcmp(method,'equiripple_fir')
                    margins = [band(1),Fs/2-band(2)];
                    margins = margins(margins>0);
                    tr = cfg.transition_fraction*diff(band);
                    if ~isempty(margins), tr = min(tr,0.5*min(margins)); end
                    args = {'TransitionHz',tr};
                end
                fd = filter_design(method,Fs,band,order,args{:});
                entry = struct('band',band,'level',level,'window',w, ...
                    'method',method,'order',order,'design',fd);
                catalog(end+1) = entry; %#ok<AGROW>
            end
        end
    end
end
end

function swf_small_file(path,payload)
if exist(path,'file')
    old = load(path);
    assert(isequaln(old,payload), ...
        'Saved metadata differs. Choose a new cfg.output_dir.');
else
    tmp = [tempname(fileparts(path)) '.mat'];
    save(tmp,'-struct','payload','-v7.3');
    [ok,msg] = movefile(tmp,path); assert(ok,msg);
end
end

function names = swf_features()
names = {'mean_amplitude','median_amplitude','mean_angular_speed', ...
    'median_negative_acceleration','n_negative_acceleration', ...
    'median_positive_acceleration','n_positive_acceleration'};
end

function swf_channel(path,m,sample_dim,ch,Fs,g,catalog,meta,cfg)
names = swf_features(); nw = meta.n_windows; nc = meta.n_configs;
if ~exist(path,'file')
    tmp = [tempname(fileparts(path)) '.mat'];
    save(tmp,'meta','-v7.3');
    out = matfile(tmp,'Writable',true);
    for k = 1:numel(names)
        out.(names{k})(nw,nc) = 0;
    end
    out.completed = false(1,nc);
    out = []; %#ok<NASGU>
    [ok,msg] = movefile(tmp,path); assert(ok,msg);
end
out = matfile(path,'Writable',true);
assert(isequaln(out.meta,meta), ...
    'Output metadata differs. Choose a new cfg.output_dir.');
for k = 1:numel(names)
    assert(isequal(size(out,names{k}),[nw nc]), 'Invalid output dimensions.');
end
completed = out.completed;
assert(islogical(completed) && isequal(size(completed),[1 nc]), ...
    'Invalid completion flags.');
if all(completed), return; end
if sample_dim == 1
    signal = double(m.Data.x(:,ch));
else
    signal = double(m.Data.x(ch,:)).';
end
assert(numel(signal)==meta.session.N && all(isfinite(signal)), ...
    'Channel must contain N finite samples.');
for c = 1:nc
    if completed(c), continue; end
    % A function boundary releases signal intermediates after each column.
    values = swf_measure(signal,Fs,catalog(c).design,g,cfg.phase);
    for k = 1:numel(names)
        out.(names{k})(:,c) = values(:,k);
    end
    % Last write: interrupted columns remain invalid and are recomputed.
    out.completed(1,c) = true;
    if mod(c,25)==0 || c==nc
        fprintf('  ch %d: configuration %d/%d saved\n',ch,c,nc);
    end
end
end

function values = swf_measure(signal,Fs,fd,g,phase_policy)
z = hilbert(filter_do(signal,Fs,fd,'phase',phase_policy));
amplitude = abs(z);
speed = diff(unwrap(angle(z)))*Fs;
z = []; %#ok<NASGU>
acceleration = diff(speed)*Fs;
assert(all(isfinite(amplitude)) && all(isfinite(speed)) && ...
    all(isfinite(acceleration)), 'Nonfinite filter/phase output; column not saved.');
values = nan(numel(g.first),7);
values(:,[5 7]) = 0;
for w = 1:numel(g.first)
    i0 = g.first(w); i1 = g.last(w);
    A = amplitude(i0:i1);
    values(w,1) = mean(A); values(w,2) = median(A);
    % Preserve original convention: derivative belongs to its later sample,
    % and may depend on samples preceding the left window boundary.
    if i1 >= max(2,i0)
        values(w,3) = mean(speed(max(1,i0-1):i1-1));
    end
    if i1 >= max(3,i0)
        a = acceleration(max(1,i0-2):i1-2);
        negative = a(a<0); positive = a(a>0);
        values(w,5) = numel(negative); values(w,7) = numel(positive);
        if ~isempty(negative), values(w,4) = median(negative); end
        if ~isempty(positive), values(w,6) = median(positive); end
    end
end
end

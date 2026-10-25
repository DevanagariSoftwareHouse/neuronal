%% Spike/LFP phase across dyadic frequency bands and temporal windows.
% MATLAB R2019a. Run from the repository root after preparing catalog data.
% If data is already available, the user-specific a00_startup is not rerun.
% All computation is explicitly CPU; no unused pool or implicit GPU roundtrip.
if ~exist('data','var') || isempty(data)
    run analysis/a00_startup.m
end
repo_root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo_root,'matlab','path'));

%% Configuration: small first run; change these selections for production.
cfg=struct();
cfg.sessions=1;
cfg.areas={'lfp_1','lfp_2','lfp_3'};
cfg.channels=1;                 % [] means every channel in each area
cfg.time_levels=0:6;            % full draft: 0:15
cfg.time_overlap=0;
cfg.frequency_levels=1:3;       % full draft: 0:7
cfg.frequency_overlap=0.5;
cfg.filter_method='butterworth';
cfg.filter_order=4;
cfg.filter_phase='zero';        % offline analysis; causal changes phase
cfg.skip_identity=true;         % skip [0,Nyquist] (no filtering)
cfg.edge_seconds=1;
cfg.edge_cycles=3;              % heuristic: max(seconds,cycles/f_low)
cfg.amplitude_floor=0;          % units of the analytic signal, not power
cfg.spike_time_scale=1;          % multiply source times; e.g. milliseconds: 1e-3
cfg.spike_time_origin_seconds=0;% subtract AFTER scaling; align to first LFP sample
cfg.max_summary_mib=256;        % plan/output estimate, excludes LFP/spike buffers
cfg.backend='hdf5';             % 'binary' also supported by the storage API
cfg.output_root=fullfile(repo_root,'data','derived','spike_lfp_intervals');
% Every execution gets a fresh root, avoiding stale results/config collisions.
if ~isfolder(cfg.output_root), mkdir(cfg.output_root); end
cfg.run_root=tempname(cfg.output_root);

%%
st=storage_create(cfg.backend,'root',cfg.run_root,'precision','preserve', ...
    'compression',0,'overwrite',false);
fprintf('Output: %s\n',st.root);
analysis_timer=tic;
for dd=cfg.sessions
    d=data(dd); Fs=double(d.srate); N=double(d.n_lfp_samples);
    validateattributes(Fs,{'double'},{'scalar','real','finite','positive'});
    validateattributes(N,{'double'},{'scalar','finite','integer','positive'});
    waveform_id=d.waveform_id(:); n_units=numel(waveform_id);
    assert(n_units>0 && numel(unique(waveform_id))==n_units, ...
        'Each mapped neuron must have one unique waveform_id.');
    source_id=d.source_id;
    session_key=storage_key('session',source_id);
    n_windows=interval_dyadic(N,Fs,cfg.time_levels,cfg.time_overlap);
    % Plan left/right/counts + outputs + working vectors (conservative estimate).
    summary_mib=(40*n_windows*n_units+128*n_windows)/2^20;
    assert(summary_mib<=cfg.max_summary_mib, ...
        'Estimated summary memory %.1f MiB exceeds limit. Reduce time levels.',summary_mib);
    windows=interval_dyadic(N,Fs,cfg.time_levels,cfg.time_overlap,'all');
    bounds=[[windows.t0]' [windows.t1]'];
    window_table=[bounds [windows.level]' [windows.overlap]' ...
        [windows.first]' [windows.last]'];

    times=double(d.spike_time.Data.x(:))*cfg.spike_time_scale-cfg.spike_time_origin_seconds;
    ids=d.spike_cluster.Data.x(:);
    assert(numel(times)==numel(ids),'Spike timestamp/ID lengths differ.');
    % Normalize IDs only after verifying exact integer representation.
    assert(all(isfinite(double(ids))) && all(double(ids)==fix(double(ids))) && ...
        all(abs(double(ids))<flintmax) && ...
        all(isfinite(double(waveform_id))) && all(double(waveform_id)==fix(double(waveform_id))) && ...
        all(abs(double(waveform_id))<flintmax), ...
        'Cluster IDs must be finite integers strictly inside the exact double range.');
    [mapped,unit_index]=ismember(double(ids),double(waveform_id));
    assert(any(mapped),'No spike IDs match waveform_id.');
    plan=spike_interval_plan(times(mapped),unit_index(mapped),n_units,N,Fs,bounds);
    meta=struct('cfg',cfg,'source_id',source_id,'fs',Fs,'N',N, ...
        'waveform_id',waveform_id,'window_columns', ...
        {{'t0_seconds','t1_seconds','level','overlap','first_sample','last_sample'}}, ...
        'unmapped_spikes',sum(~mapped),'excluded_timestamps',plan.excluded_spikes, ...
        'clock','LFP sample k occurs at (k-1)/fs seconds', ...
        'spike_phase_sampling','previous-or-coincident sample; no interpolation');
    storage_write(st,[session_key '/windows'],window_table,'metadata',meta);
    storage_write(st,[session_key '/spike_count'],plan.counts,'metadata',meta);
    fprintf('Session %s: %d windows, %d units; %d unmapped, %d invalid/outside spikes.\n', ...
        char(string(source_id)),n_windows,n_units,sum(~mapped),plan.excluded_spikes);
    clear times ids mapped unit_index windows;

    % Choose generator N/fs parameters whose duration is exactly Fs/2 Hz,
    % including non-integer Fs. Width restrictions still apply to the bank.
    frequency_N=ceil(Fs); frequency_scale=frequency_N/(Fs/2);
    bands=interval_dyadic(frequency_N,frequency_scale, ...
        cfg.frequency_levels,cfg.frequency_overlap,'all');
    frequency_table=[(1:numel(bands))' [bands.t0]' [bands.t1]' ...
        [bands.level]' [bands.overlap]'];
    frequency_meta=meta; frequency_meta.columns= ...
        {'frequency_id','low_hz','high_hz','level','overlap'};
    storage_write(st,[session_key '/frequency_bands'],frequency_table,'metadata',frequency_meta);
    for la=1:numel(cfg.areas)
        area=cfg.areas{la}; mmap=d.(area);
        fmt=mmap.Format;
        assert(iscell(fmt)&&size(fmt,1)==1&&strcmp(fmt{1,3},'x'), ...
            'Expected one numeric memmap field x.');
        dims=fmt{1,2};
        assert(numel(dims)==2 && dims(1)==N, ...
            'LFP mapping must be samples-by-channels; check catalog orientation.');
        channels=cfg.channels; if isempty(channels), channels=1:dims(2); end
        validateattributes(channels,{'numeric'},{'vector','integer','positive','<=',dims(2)});
        for ch=channels(:)'
            signal=double(mmap.Data.x(:,ch));
            assert(all(isfinite(signal)),'LFP contains nonfinite samples.');
            for fi=1:numel(bands)
                band=[bands(fi).t0 bands(fi).t1];
                fd=filter_design(cfg.filter_method,Fs,band,cfg.filter_order);
                if cfg.skip_identity && strcmp(fd.kind,'identity'), continue; end
                % Lowpass/DC bands use their upper cutoff as an edge scale;
                % their Hilbert phase is not a narrowband oscillatory phase.
                edge_frequency=band(1); if edge_frequency==0, edge_frequency=band(2); end
                edge=max(cfg.edge_seconds,cfg.edge_cycles/edge_frequency);
                if 2*edge>=N/Fs
                    warning('spike_lfp:ShortSession','Skipping [%g,%g] Hz: no interior after edge exclusion.',band);
                    continue;
                end
                filtered=filter_do(signal,Fs,fd,'phase',cfg.filter_phase,'gpu','cpu');
                analytic=hilbert(filtered);
                result=spike_interval_features(plan,analytic,edge,cfg.amplitude_floor);
                key=storage_key('session',source_id,'area',area,'channel',ch, ...
                    'frequency',fi,'filter',sprintf('%s_order%d_%s', ...
                    cfg.filter_method,cfg.filter_order,cfg.filter_phase));
                band_meta=meta; band_meta.band_hz=band; band_meta.frequency_interval=bands(fi);
                band_meta.filter=fd; band_meta.edge_seconds=edge;
                band_meta.edge_policy='heuristic exclusion, not a validated settling-time bound';
                band_meta.narrowband_candidate=strcmp(fd.kind,'bandpass');
                band_meta.valid_phase_time=[edge N/Fs-edge];
                exposure=max(0,min(bounds(:,2),N/Fs-edge)-max(bounds(:,1),edge));
                storage_write(st,[key '/phase_exposure_seconds'],exposure,'metadata',band_meta);
                names=fieldnames(result);
                for k=1:numel(names)
                    storage_write(st,[key '/' names{k}],result.(names{k}),'metadata',band_meta);
                end
                % Completion marker is written LAST; missing marker means partial output.
                storage_write(st,[key '/complete'],uint8(1),'metadata',band_meta);
                fprintf('  %s channel %d band %d/%d [%g,%g] Hz\n',area,ch,fi,numel(bands),band);
                clear filtered analytic result;
            end
        end
    end
    storage_write(st,[session_key '/complete'],uint8(1),'metadata',meta);
    clear plan;
end
storage_close(st);
fprintf('Finished in %.1f s. Output: %s\n',toc(analysis_timer),st.root);

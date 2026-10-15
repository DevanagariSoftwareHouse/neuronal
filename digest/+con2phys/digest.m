function entries = digest(sourceRoot, rawRoot, varargin)
%CON2PHYS.DIGEST Convert CON2PHYS MAT/XLSX experiments to neuronal BIN records.
%   ENTRIES = CON2PHYS.DIGEST(SOURCE_ROOT,RAW_ROOT,'Animals',1:18)
%   Expects SOURCE_ROOT/01/lfp_1.mat, ... , SOURCE_ROOT/18/.
%   Does NOT update the global catalog. Call neuronal_register after validation.
%   The input MAT LFP variables are channels x samples; output BIN is
%   samples x channels with each channel time-series stored contiguously.
%   Normalizes LFP, spike timestamps, clusters, and unit-average waveforms.
%   Preserves brain_areas and trial table in the small in-memory metadata.
%
%   'RecordStart' sets a globally unique starting integer for IDs (default 1).
%   'Overwrite' is false by default. Keep original source files immutable.
    p = inputParser;
    addParameter(p,'Animals',1:18,@(x) isnumeric(x)&&isvector(x)&& ...
        ~isempty(x)&&all(x>=1 & x<=18 & x==fix(x))&&numel(unique(x))==numel(x));
    addParameter(p,'RecordStart',1,@(x) isnumeric(x)&&isscalar(x)&& ...
        isfinite(x)&&x>=1&&x==fix(x));
    addParameter(p,'SamplingRateHz',500,@(x) isnumeric(x)&&isscalar(x)&& ...
        isfinite(x)&&x>0);
    addParameter(p,'Overwrite',false,@(x) islogical(x)&&isscalar(x));
    parse(p,varargin{:});
    cfg = p.Results;
    sourceRoot = char(sourceRoot);
    rawRoot = char(rawRoot);
    assert(isfolder(sourceRoot),'con2phys:digest:Source', ...
        'Source directory not found: %s',sourceRoot);
    entries = struct([]);

    for animalId = reshape(cfg.Animals,1,[])
        sourceId = sprintf('%02d',animalId);
        sourceDir = fullfile(sourceRoot,sourceId);
        assert(isfolder(sourceDir),'con2phys:digest:Animal', ...
            'Missing animal folder: %s',sourceDir);
        recordId = sprintf('%05d',cfg.RecordStart+animalId-1);
        outDir = fullfile(rawRoot,recordId);
        if ~isfolder(outDir), mkdir(outDir); end
        files = struct([]);
        nSamples = NaN;

        for region = 1:3
            name = sprintf('lfp_%d',region);
            variable = sprintf('lfp%d',region);
            sourceFile = fullfile(sourceDir,[name '.mat']);
            matrix = load_required(sourceFile,variable);
            assert(isnumeric(matrix) && ismatrix(matrix) && ~isempty(matrix), ...
                'con2phys:digest:LFP','Invalid %s in %s',variable,sourceFile);
            assert(isa(matrix,'double'), ...
                'con2phys:digest:LFPClass','Expected double LFP in %s',sourceFile);
            if isnan(nSamples)
                nSamples = size(matrix,2);
            else
                assert(nSamples==size(matrix,2),'con2phys:digest:Time', ...
                    'LFP sample counts differ within animal %s.',sourceId);
            end
            info = neuronal_write_binary(matrix,fullfile(outDir,[name '.bin']), ...
                'SampleAxis',2,'Overwrite',cfg.Overwrite);
            clear matrix
            info = describe(info,name,'lfp',sourceFile,variable,cfg.SamplingRateHz);
            nChannels = info.shape(2);
            % Only the measured channel order is known. Do not pretend the
            % nominal 20 um pitch establishes actual selected-site geometry.
            pos = struct('relative',true,'frame','probe', ...
                'unit','um','value',nan(nChannels,1), ...
                'depth_order',(1:nChannels)', ...
                'nominal_pitch_um',20, ...
                'status','coordinates_unknown', ...
                'stereotaxic',struct('azimuth',NaN,'elevation',NaN));
            info.position = pos;
            files = append_file(files,info);
        end

        sourceFile = fullfile(sourceDir,'spikes.mat');
        spikeTimes = load_required(sourceFile,'spikes');
        sourceClusters = fullfile(sourceDir,'clusters.mat');
        clusterIds = load_required(sourceClusters,'clusters');
        assert(isvector(spikeTimes) && isvector(clusterIds) && ...
            numel(spikeTimes)==numel(clusterIds), ...
            'con2phys:digest:Spikes','Spike timestamps/clusters not aligned.');
        assert(isa(spikeTimes,'double') && isa(clusterIds,'int32'), ...
            'con2phys:digest:SpikeClass','Unexpected spike/cluster data types.');
        nSpikes = numel(spikeTimes);
        info = neuronal_write_binary(spikeTimes(:), ...
            fullfile(outDir,'spike_time.bin'),'Overwrite',cfg.Overwrite);
        info = describe(info,'spike_time','spike_times',sourceFile,'spikes',NaN);
        files = append_file(files,info);
        info = neuronal_write_binary(clusterIds(:), ...
            fullfile(outDir,'spike_cluster.bin'),'Overwrite',cfg.Overwrite);
        info = describe(info,'spike_cluster','spike_clusters', ...
            sourceClusters,'clusters',NaN);
        files = append_file(files,info);
        clear spikeTimes clusterIds

        sourceFile = fullfile(sourceDir,'waveforms.mat');
        waveforms = load_required(sourceFile,'wf');
        assert(isa(waveforms,'single') && ismatrix(waveforms), ...
            'con2phys:digest:Waveforms','Expected single wf matrix.');
        nUnits = size(waveforms,1);
        info = neuronal_write_binary(waveforms, ...
            fullfile(outDir,'waveforms.bin'), ...
            'SampleAxis',2,'Overwrite',cfg.Overwrite);
        info = describe(info,'waveforms','waveforms',sourceFile,'wf',30000);
        files = append_file(files,info);
        clear waveforms

        anatomyFile = fullfile(sourceDir,'brain_area.mat');
        brainAreas = load_required(anatomyFile,'brain_areas');
        trialsFile = fullfile(sourceDir,'trial_data.xlsx');
        assert(isfile(trialsFile),'con2phys:digest:Trials', ...
            'Missing trials spreadsheet: %s',trialsFile);
        trialTable = readtable(trialsFile);
        % Retain original column names/values; do not guess their meanings.
        behavior = struct('trials',table2struct(trialTable), ...
            'variable_names',{trialTable.Properties.VariableNames}, ...
            'source_file',trialsFile);

        record = struct('id',recordId,'source_id',sourceId, ...
            'path',outDir,'source_path',sourceDir, ...
            'file',files,'brain_areas',brainAreas, ...
            'behavior',behavior, ...
            'n_spikes',nSpikes,'n_waveforms',nUnits, ...
            'n_lfp_samples',nSamples);
        if isempty(entries)
            entries = record;
        else
            entries(end+1) = record; %#ok<AGROW>
        end
    end
end

function info = describe(info,name,kind,sourceFile,variable,fs)
    info.name = name;
    info.type = kind;
    info.source_file = sourceFile;
    info.source_variable = variable;
    info.sampling_rate_hz = fs;
    info.time_origin_s = NaN;
    info.units = 'unknown';
    info.position = struct([]);
end

function files = append_file(files,info)
    if isempty(files)
        files = info;
    else
        files(end+1) = info; %#ok<AGROW>
    end
end

function value = load_required(path,variable)
    assert(isfile(path),'con2phys:digest:Missing','Missing source: %s',path);
    s = load(path,variable);
    assert(isfield(s,variable),'con2phys:digest:Variable', ...
        'Missing variable %s in %s',variable,path);
    value = s.(variable);
end

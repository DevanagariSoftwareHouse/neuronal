function jsonPath = neuronal_catalog_json(catalogPath, jsonPath)
%NEURONAL_CATALOG_JSON Export the binary descriptors of catalog.mat as JSON.
%   Writes only what a non-MATLAB reader needs to map the BIN files
%   (path, dtype, shape, endian, offset, sampling rate). catalog.mat stays
%   the source of truth; rerun after every neuronal_register.
%
%   SYNTAX
%     jsonPath = neuronal_catalog_json(catalogPath)
%     jsonPath = neuronal_catalog_json(catalogPath, jsonPath)
%
%   INPUTS
%     catalogPath: catalog.mat path or its folder (as in neuronal_catalog).
%     jsonPath: Output file; default catalog.json next to catalog.mat.
%
%   OUTPUTS
%     jsonPath: Path written.
%
%   EXAMPLE
%     neuronal_catalog_json('data/neuronal/catalog.mat');
%     % -> data/neuronal/catalog.json, read by rust/a00_first_look
%
    catalog = neuronal_catalog(catalogPath);
    if nargin < 2 || isempty(jsonPath)
        if isfolder(catalogPath)
            folder = char(catalogPath);
        else
            folder = fileparts(char(catalogPath));
        end
        jsonPath = fullfile(folder,'catalog.json');
    end

    datasets = cell(1,numel(catalog));
    for k = 1:numel(catalog)
        records = cell(1,numel(catalog(k).data));
        for j = 1:numel(catalog(k).data)
            r = catalog(k).data(j);
            files = cell(1,numel(r.file));
            for f = 1:numel(r.file)
                d = r.file(f);
                offset = 0;
                if isfield(d,'offset_bytes'), offset = double(d.offset_bytes); end
                files{f} = struct( ...
                    'name',char(field_or(d,'name','')), ...
                    'type',char(field_or(d,'type','')), ...
                    'path',strrep(char(d.path),'\','/'), ...
                    'dtype',char(d.dtype), ...
                    'shape',{num2cell(double(d.shape(:).'))}, ...
                    'endian',char(d.endian), ...
                    'offset_bytes',offset, ...
                    'sampling_rate_hz',double(field_or(d,'sampling_rate_hz',NaN)));
            end
            records{j} = struct('id',char(r.id), ...
                'source_id',char(field_or(r,'source_id','')), ...
                'files',{files});
        end
        datasets{k} = struct('alias',char(catalog(k).digest_alias), ...
            'records',{records});
    end
    doc = struct('schema_version',1,'source',char(catalogPath), ...
        'datasets',{datasets});

    fid = fopen(jsonPath,'w');
    assert(fid >= 0,'neuronal:catalog_json:Open','Cannot write %s',jsonPath);
    cleanup = onCleanup(@() fclose(fid));
    fwrite(fid,jsonencode(doc),'char');
end

function v = field_or(s,name,default)
    if isfield(s,name) && ~isempty(s.(name))
        v = s.(name);
    else
        v = default;
    end
end

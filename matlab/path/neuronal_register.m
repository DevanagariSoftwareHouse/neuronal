function catalog = neuronal_register(catalogPath, alias, digestPath, entries, varargin)
%NEURONAL_REGISTER Publish a dataset's normalized records to catalog.mat.
%   Only this single-writer function updates the catalog. Digest workers
%   produce files and entries; they must not write catalog.mat concurrently.
%   'Replace',true replaces an existing dataset alias (not other datasets).
%
%   SYNTAX
%     catalog = neuronal_register(catalogPath, alias, digestPath, entries, varargin)
%
%   INPUTS
%     catalogPath: Target catalog MAT-file path (created if absent).
%     alias: Nonempty dataset alias, unique in the catalog.
%     digestPath: Nonempty provenance/digest path string stored as metadata.
%     entries: Nonempty record struct array with unique id and nonempty file descriptor array;
%       files are validated.
%     varargin: Replace=false by default; true replaces an existing alias. Root resolves
%       relative binary paths (default repository root).
%
%   OUTPUTS
%     catalog: Updated struct array with schema_version, digest_alias, digest_path and data.
%       Also writes catalogPath atomically.
%
%   The little-endian writer fixture validates on a little-endian host.
%
%   EXAMPLE
%     folder = tempname; mkdir(folder);
%     d = neuronal_write_binary(single(randn(100,2)),fullfile(folder,'toy.bin'));
%     entry = struct('id','toy-record','file',d);
%     catalog = neuronal_register(fullfile(folder,'catalog.mat'),'toy','toy.m',entry);
%     % The example writes a temporary catalog and binary, then removes them.
%     rmdir(folder,'s');
%
    p = inputParser;
    addParameter(p,'Replace',false,@(x) islogical(x)&&isscalar(x));
    addParameter(p,'Root',[],@(x) isempty(x)||ischar(x)||isstring(x));
    parse(p,varargin{:});
    catalogPath = char(catalogPath);
    alias = char(alias);
    digestPath = char(digestPath);
    assert(~isempty(alias) && ~isempty(digestPath), ...
        'neuronal:register:Alias','Alias/digest path must be nonempty.');
    assert(isstruct(entries) && ~isempty(entries), ...
        'neuronal:register:Entries','Expected a nonempty record struct array.');
    ids = cell(1,numel(entries));
    for j = 1:numel(entries)
        assert(isfield(entries(j),'id') && isfield(entries(j),'file'), ...
            'neuronal:register:Record','Record requires id and file fields.');
        ids{j} = char(entries(j).id);
        assert(isstruct(entries(j).file) && ~isempty(entries(j).file), ...
            'neuronal:register:Files','Empty file list for record %s.',ids{j});
        for f = 1:numel(entries(j).file)
            neuronal_validate_file(entries(j).file(f),p.Results.Root);
        end
    end
    assert(numel(unique(ids))==numel(ids), ...
        'neuronal:register:Duplicate','Duplicate record IDs.');

    if isfile(catalogPath)
        catalog = neuronal_catalog(catalogPath);
    else
        catalog = struct('schema_version',{},'digest_alias',{}, ...
            'digest_path',{},'data',{});
    end
    found = find(strcmp({catalog.digest_alias},alias));
    assert(numel(found)<=1,'neuronal:register:Catalog','Repeated dataset aliases.');
    if ~isempty(found)
        assert(p.Results.Replace,'neuronal:register:Exists', ...
            'Dataset alias %s already exists; specify Replace=true.',alias);
    end
    for k = 1:numel(catalog)
        if k==found, continue; end
        other = {catalog(k).data.id};
        assert(~any(ismember(ids,other)), ...
            'neuronal:register:Collision','Record ID belongs to another dataset.');
    end
    item = struct('schema_version',1,'digest_alias',alias, ...
        'digest_path',digestPath,'data',entries);
    if isempty(found)
        catalog(end+1) = item;
    else
        catalog(found) = item;
    end
    parent = fileparts(catalogPath);
    if isempty(parent), parent = '.'; end
    if ~isfolder(parent), mkdir(parent); end
    tmp = [tempname(parent) '.mat'];
    guard = onCleanup(@() delete_if_exists(tmp));
    save(tmp,'catalog','-v7');
    [ok,msg] = movefile(tmp,catalogPath,'f');
    assert(ok,'neuronal:register:Publish','Catalog publish failed: %s',msg);
    clear guard
end

function delete_if_exists(path)
    if isfile(path), delete(path); end
end

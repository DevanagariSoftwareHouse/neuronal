function catalog = neuronal_register(catalogPath, alias, digestPath, entries, varargin)
%NEURONAL_REGISTER Publish a dataset's normalized records to catalog.mat.
%   Only this single-writer function updates the catalog. Digest workers
%   produce files and entries; they must not write catalog.mat concurrently.
%   'Replace',true replaces an existing dataset alias (not other datasets).
%
%   SIGNATURE DESCRIPTION
%     catalogPath — the catalog path value; expected shape, units, and constraints are stated in the notes above.
%     alias — the alias value; expected shape, units, and constraints are stated in the notes above.
%     digestPath — the digest path value; expected shape, units, and constraints are stated in the notes above.
%     entries — the entries value; expected shape, units, and constraints are stated in the notes above.
%     varargin — optional name/value pairs described in the notes above.
%   RETURNS
%     catalog — the returned catalog; see the summary above for meaning and units.
%   USAGE EXAMPLE (uses default options; add documented name/value pairs as needed)
%     % Prepare the input variables above with the documented dimensions and units.
%     catalog = neuronal_register(catalogPath, alias, digestPath, entries);
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

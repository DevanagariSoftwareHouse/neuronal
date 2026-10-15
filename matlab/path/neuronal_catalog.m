function catalog = neuronal_catalog(catalogPath)
%NEURONAL_CATALOG Load the persistent dataset index (never loads raw arrays).
%   CATALOG = NEURONAL_CATALOG(PATH) reads PATH/catalog.mat if PATH is a
%   directory, otherwise reads the given .mat file.
    if nargin < 1 || isempty(catalogPath)
        root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        catalogPath = fullfile(root,'data','neuronal','catalog.mat');
    end
    catalogPath = char(catalogPath);
    if isfolder(catalogPath)
        catalogPath = fullfile(catalogPath,'catalog.mat');
    end
    assert(isfile(catalogPath), 'neuronal:catalog:NotFound', ...
        'Catalog does not exist: %s', catalogPath);
    s = load(catalogPath,'catalog');
    assert(isfield(s,'catalog') && isstruct(s.catalog), ...
        'neuronal:catalog:Invalid', 'Missing struct variable catalog.');
    catalog = s.catalog;
end

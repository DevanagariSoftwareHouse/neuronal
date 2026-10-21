function catalog = neuronal_catalog(catalogPath)
%NEURONAL_CATALOG Load the persistent dataset index (never loads raw arrays).
%   CATALOG = NEURONAL_CATALOG(PATH) reads PATH/catalog.mat if PATH is a
%   directory, otherwise reads the given .mat file.
%
%   SYNTAX
%     catalog = neuronal_catalog(catalogPath)
%
%   INPUTS
%     catalogPath: Catalog MAT-file path or directory containing catalog.mat; default
%       repository data/neuronal/catalog.mat.
%
%   OUTPUTS
%     catalog: Loaded struct variable named catalog; only metadata is read.
%
%   EXAMPLE
%     folder = tempname; mkdir(folder);
%     catalog = struct('schema_version',1,'digest_alias','toy','digest_path','toy.m');
%     save(fullfile(folder,'catalog.mat'),'catalog');
%     loaded = neuronal_catalog(folder);
%     % This creates a minimal metadata fixture, not a raw-data registration.
%     rmdir(folder,'s');
%
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

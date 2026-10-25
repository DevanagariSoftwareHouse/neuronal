function st = storage_create(backend,varargin)
%STORAGE_CREATE Initialize storage; no persistent handles in the descriptor.
% ST=storage_create('hdf5','root',ROOT,'chunk_samples',65536).
% Options are the fields of STORAGE_DEFAULTS except backend.
if nargin<1 || isempty(backend), backend='hdf5'; end
st=storage_defaults(backend);
p=inputParser; p.FunctionName=mfilename; p.PartialMatching=false;
names=fieldnames(st);
for k=1:numel(names)
    if ~strcmp(names{k},'backend'), addParameter(p,names{k},st.(names{k})); end
end
parse(p,varargin{:}); st=p.Results; st.backend=backend;
st=storage_validate(st);
% Resolve relative roots once, so changing cwd does not relocate the store.
root_file=java.io.File(st.root);
st.root=char(root_file.getCanonicalPath());
if any(strcmp(st.backend,{'sqlite','hybrid'})) && exist('sqlite','file')~=2
    error('storage:Dependency','SQLite requires the Database Toolbox sqlite interface.');
end
if ~isfolder(st.root)
    if st.readonly || ~st.create_parents
        error('storage:MissingRoot','Storage root does not exist.');
    end
    [ok,msg]=mkdir(st.root); if ~ok, error('storage:IO','%s',msg); end
end
storage_internal('initialize',st);
end

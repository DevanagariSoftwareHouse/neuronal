function st = storage_hybrid(varargin)
%STORAGE_HYBRID SQLite catalog with HDF5 or binary array payloads.
% ST=storage_hybrid('root',ROOT,...) forwards STORAGE_CREATE options.
st=storage_create('hybrid',varargin{:});
end

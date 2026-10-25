function st = storage_hdf5(varargin)
%STORAGE_HDF5 Chunked HDF5 arrays, compression disabled by default.
% ST=storage_hdf5('root',ROOT,...) forwards STORAGE_CREATE options.
st=storage_create('hdf5',varargin{:});
end

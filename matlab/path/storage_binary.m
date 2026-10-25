function st = storage_binary(varargin)
%STORAGE_BINARY Column-major binary arrays with MAT sidecar metadata.
% ST=storage_binary('root',ROOT,...) forwards STORAGE_CREATE options.
st=storage_create('binary',varargin{:});
end

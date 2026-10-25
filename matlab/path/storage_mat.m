function st = storage_mat(varargin)
%STORAGE_MAT MAT serialization, -v7.3 and no compression by default.
% ST=storage_mat('root',ROOT,...) forwards STORAGE_CREATE options.
st=storage_create('mat',varargin{:});
end

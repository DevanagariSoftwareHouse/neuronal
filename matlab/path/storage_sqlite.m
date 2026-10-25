function st = storage_sqlite(varargin)
%STORAGE_SQLITE SQLite catalog with type-preserving MAT payloads.
% ST=storage_sqlite('root',ROOT,...) forwards STORAGE_CREATE options.
st=storage_create('sqlite',varargin{:});
end

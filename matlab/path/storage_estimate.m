function e = storage_estimate(operation,shape,varargin)
%STORAGE_ESTIMATE Estimate memory and disk for dense real storage I/O.
% E=STORAGE_ESTIMATE('write',[N C],'backend','binary','precision','int16')
% E=STORAGE_ESTIMATE('read',[N C],'backend','mat', ...
%      'mat_version','-v7','range_rows',[1 1000])
% Also accepts 'storage_read', 'storage_write' or corresponding handles.
% Backend options are those of RESOURCE_ESTIMATE_STORAGE_IO.
% The result includes cpu_bytes, gpu_bytes, disk_bytes and payload_bytes.
% Writes assume input already resident; sizes are advisory heuristics.
narginchk(2,inf);
if isa(operation,'function_handle'),operation=func2str(operation);end
assert((ischar(operation)||isstring(operation))&& ...
    isscalar(string(operation)), ...
    'storage_estimate:Operation','Expected a read/write operation.');
switch lower(char(operation))
    case {'read','storage_read'}
        op='read';
    case {'write','storage_write'}
        op='write';
    otherwise
        error('storage_estimate:Operation','Expected read or write.');
end
e=resource_estimate_storage_io(op,shape,varargin{:});
end

function st = storage_write(st,key,x,varargin)
%STORAGE_WRITE Store one complete artifact; overwrite is opt-in.
% ST=storage_write(ST,KEY,X,'metadata',STRUCT). GPU inputs require gather first.
% Precision conversion occurs only when explicitly configured.
storage_internal('write',st,key,x,varargin{:});
end

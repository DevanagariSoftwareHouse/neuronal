function x = storage_read(st,key,varargin)
%STORAGE_READ Read an artifact or an inclusive first-dimension range.
% X=storage_read(ST,KEY); X=storage_read(ST,KEY,[FIRST LAST]).
% Ranges select rows across every remaining dimension; preserve orientation.
x=storage_internal('read',st,key,varargin{:});
end

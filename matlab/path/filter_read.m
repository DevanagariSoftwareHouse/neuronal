function [value,manifest] = filter_read(folder,varargin)
%FILTER_READ Read selected array indices from a persistent filter artifact.
% [X,M] = filter_read(FOLDER,I,J,...) indexes stored dimensions; ':' allowed.
% With no indices, reads the whole array. Complex planes are reassembled.
% Example: x=filter_read('derived/example',1:500,1);
[map,manifest]=filter_open(folder);
if isempty(varargin)
    value=map.Data.real;
    if manifest.is_complex, value=complex(value,map.Data.imag); end
else
    value=map.Data.real(varargin{:});
    if manifest.is_complex, value=complex(value,map.Data.imag(varargin{:})); end
end
end

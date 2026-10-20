function info = neuronal_write_binary(x, filename, varargin)
%NEURONAL_WRITE_BINARY Persist a numeric matrix as a headerless little-endian BIN.
%   Name/value: 'SampleAxis' = 1 (default) or 2; 'Overwrite' = false.
%   For channels x samples use SampleAxis=2: writes each complete channel
%   contiguously, yielding [samples x channels] on disk without TRANSPOSE.
%   A temporary file is validated and atomically renamed on the same volume.
%
%   SYNTAX
%     info = neuronal_write_binary(x, filename, varargin)
%
%   INPUTS
%     x: Nonempty real 2-D numeric matrix; supported classes are double/single and
%       signed/unsigned 8/16/32/64-bit integers.
%     filename: Destination path; parent directories are created.
%     varargin: SampleAxis=1 (default) or 2; Overwrite=false (logical); ChunkSamples=2^19
%       (positive integer).
%
%   OUTPUTS
%     info: Descriptor with path, dtype, shape (samples-by-channels), layout, endian=ieee-le,
%       offset_bytes=0, bytes, sample_axis=1 and channel_axis=2.
%
%   EXAMPLE
%     filename = [tempname '.bin'];
%     lfp = single(randn(3,1000)); % channels by samples
%     info = neuronal_write_binary(lfp,filename,'SampleAxis',2,'ChunkSamples',256);
%     % info.shape is [1000 3]; existing files require Overwrite=true.
%     delete(filename);
%
    validateattributes(x,{'numeric'},{'real','2d','nonempty'},mfilename,'x');
    supported = {'double','single','int8','uint8','int16','uint16', ...
                 'int32','uint32','int64','uint64'};
    dtype = class(x);
    assert(ismember(dtype,supported),'neuronal:write:Type', ...
        'Unsupported class %s; cast explicitly first.',dtype);
    p = inputParser;
    addParameter(p,'SampleAxis',1,@(v) isequal(v,1)||isequal(v,2));
    addParameter(p,'Overwrite',false,@(v) islogical(v) && isscalar(v));
    addParameter(p,'ChunkSamples',2^19,@(v) isscalar(v)&&isnumeric(v)&& ...
        isfinite(v)&&v>=1&&fix(v)==v);
    parse(p,varargin{:});
    cfg = p.Results;
    filename = char(filename);
    parent = fileparts(filename);
    if isempty(parent), parent = '.'; end
    if ~isfolder(parent), mkdir(parent); end
    assert(cfg.Overwrite || ~isfile(filename), ...
        'neuronal:write:Exists','Output exists: %s',filename);
    tmp = [tempname(parent) '.part'];
    tempGuard = onCleanup(@() cleanup_temporary(tmp));
    [fid,msg] = fopen(tmp,'w','ieee-le');
    assert(fid>=0,'neuronal:write:Open','Could not open %s: %s',tmp,msg);
    closeGuard = onCleanup(@() fclose(fid));
    if cfg.SampleAxis == 1
        shape = size(x);
        nChannels = size(x,2);
        for c = 1:nChannels
            for lo = 1:cfg.ChunkSamples:size(x,1)
                hi = min(size(x,1),lo+cfg.ChunkSamples-1);
                n = fwrite(fid,x(lo:hi,c),dtype);
                assert(n==hi-lo+1,'neuronal:write:Short','Short binary write.');
            end
        end
    else
        shape = [size(x,2) size(x,1)];
        nChannels = size(x,1);
        for c = 1:nChannels
            for lo = 1:cfg.ChunkSamples:size(x,2)
                hi = min(size(x,2),lo+cfg.ChunkSamples-1);
                n = fwrite(fid,x(c,lo:hi),dtype);
                assert(n==hi-lo+1,'neuronal:write:Short','Short binary write.');
            end
        end
    end
    clear closeGuard % fclose before publishing
    sizes = struct('double',8,'single',4,'int8',1,'uint8',1, ...
        'int16',2,'uint16',2,'int32',4,'uint32',4,'int64',8,'uint64',8);
    stat = dir(tmp);
    assert(stat.bytes==prod(shape)*sizes.(dtype), ...
        'neuronal:write:Size','Incomplete binary output.');
    [ok,msg] = movefile(tmp,filename,'f');
    assert(ok,'neuronal:write:Move','Publish failed: %s',msg);
    clear tempGuard
    info = struct('path',filename,'dtype',dtype,'shape',shape, ...
        'layout','column-major','endian','ieee-le', ...
        'offset_bytes',0,'bytes',stat.bytes, ...
        'sample_axis',1,'channel_axis',2);
end

function cleanup_temporary(path)
    if isfile(path), delete(path); end
end

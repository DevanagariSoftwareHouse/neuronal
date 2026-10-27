function e = resource_estimate_storage_io(operation,shape,varargin)
%RESOURCE_ESTIMATE_STORAGE_IO Estimate dense real storage READ/WRITE buffers.
% E=RESOURCE_ESTIMATE_STORAGE_IO('write',[N C],'backend','binary',...
%     'precision','int16')
% E=RESOURCE_ESTIMATE_STORAGE_IO('read',[N C],'backend','mat',...
%     'mat_version','-v7','range_rows',[1 1000])
% For -v7 MAT partial reads, LOAD materializes the full stored array first.
% Advisory heuristic; inputs are already resident for writes.
assert(choice(operation,{'read','write'}),...
    'resource_estimate_storage_io:Operation','Use read or write.');
validateattributes(shape,{'numeric'},...
    {'vector','real','integer','nonnegative','finite','nonempty'});
shape=double(shape(:)');
p=inputParser;p.PartialMatching=false;
p.addParameter('precision','double',@(x)choice(x, ...
    {'logical','int8','uint8','int16','uint16','int32','uint32',...
    'single','int64','uint64','double'}));
p.addParameter('backend','binary',@(x)choice(x, ...
    {'binary','hdf5','mat','sqlite','hybrid'}));
p.addParameter('array_backend','hdf5',@(x)choice(x,{'binary','hdf5','mat'}));
p.addParameter('mat_version','-v7.3',@(x)choice(x,{'-v7','-v7.3'}));
p.addParameter('range_rows',[],@(x)isnumeric(x)&&isreal(x)&&...
    (isempty(x)||(numel(x)==2&&all(isfinite(x))&&...
    all(x==fix(x))&&all(x>=1))));
p.addParameter('safety_factor',2,@(x)isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x)&&x>=1);
p.parse(varargin{:});o=p.Results;
backend=lower(char(o.backend));
if strcmp(backend,'sqlite'),payload='mat';
elseif strcmp(backend,'hybrid'),payload=lower(char(o.array_backend));
else,payload=backend;
end
types={'logical','int8','uint8','int16','uint16','int32',...
    'uint32','single','int64','uint64','double'};
widths=[1 1 1 2 2 4 4 4 8 8 8];
width=widths(strcmpi(char(o.precision),types));
full_bytes=prod(shape)*width;
assert(isfinite(full_bytes),'resource_estimate_storage_io:Size','Array too large.');
rows=shape(1);
if ~isempty(o.range_rows)
    range=double(o.range_rows(:)');
    assert(range(2)>=range(1)&&range(2)<=rows,...
        'resource_estimate_storage_io:Range','Row range outside array.');
    rows=range(2)-range(1)+1;
end
out_bytes=prod([rows shape(2:end)])*width;
op=lower(char(operation));
if strcmp(op,'write')
    assert(isempty(o.range_rows),'resource_estimate_storage_io:Range',...
        'Writes do not accept range_rows.');
    switch payload
        case 'binary',multiplier=0.5;
        case 'hdf5',multiplier=2;
        otherwise,multiplier=3;
    end
    cpu=ceil(full_bytes*multiplier*o.safety_factor);
    disk=ceil(full_bytes*1.1+8192);
    retained=0;
else
    disk=0;retained=out_bytes;
    if strcmp(payload,'mat')&&strcmp(char(o.mat_version),'-v7')&&...
            ~isempty(o.range_rows)
        cpu=ceil((full_bytes+out_bytes)*o.safety_factor);
    else
        cpu=ceil(out_bytes*2*o.safety_factor);
    end
end
e=struct('cpu_bytes',cpu,'gpu_bytes',0,'disk_bytes',disk,...
    'task_bytes',cpu,'payload_bytes',ceil(full_bytes),...
    'retained_output_bytes',ceil(retained),...
    'safety_factor',o.safety_factor,'backend',payload,...
    'operation',op,'confidence','heuristic',...
    'model','storage dense array I/O',...
    'notes','Memory and staged disk sizes are estimates, not strict bounds.');
end
function tf=choice(x,values)
tf=(ischar(x)||isstring(x))&&isscalar(string(x))&&any(strcmpi(char(x),values));
end

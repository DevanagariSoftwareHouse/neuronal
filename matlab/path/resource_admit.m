function a = resource_admit(snapshot,request,varargin)
%RESOURCE_ADMIT Advisory RAM/VRAM/disk budget, including in-flight requests.
% A=RESOURCE_ADMIT(SNAPSHOT,REQUEST,'ram_reserve',BYTES,'inflight',STRUCT)
% Missing capacity fails closed for resources actually requested.
p=inputParser; p.PartialMatching=false;
p.addParameter('ram_reserve',0,@validBytes);
p.addParameter('gpu_reserve',0,@validBytes);
p.addParameter('disk_reserve',0,@validBytes);
p.addParameter('inflight',struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',0),...
    @(x)isstruct(x)&&isscalar(x));
p.parse(varargin{:});o=p.Results;
assert(isstruct(snapshot)&&isscalar(snapshot),'resource_admit:Snapshot', ...
    'Snapshot must be a scalar struct.');
assert(isstruct(request)&&isscalar(request)&& ...
    isfield(request,'cpu_bytes')&&isfield(request,'gpu_bytes'), ...
    'resource_admit:Request','Request needs cpu_bytes and gpu_bytes.');
assert(validBytes(request.cpu_bytes)&&validBytes(request.gpu_bytes),...
    'resource_admit:Request','Requested bytes must be finite nonnegative scalars.');
disk_bytes=0;
if isfield(request,'disk_bytes'),disk_bytes=request.disk_bytes;end
assert(validBytes(disk_bytes),'resource_admit:Request','Invalid disk request.');
in=o.inflight;
names={'cpu_bytes','gpu_bytes','disk_bytes'};
for k=1:numel(names)
    field=names{k};
    if ~isfield(in,field),in.(field)=0;end
    assert(validBytes(in.(field)),'resource_admit:Inflight', ...
        'In-flight reservations must be finite nonnegative scalars.');
end
ram_left=capacity(snapshot,'ram_available')-o.ram_reserve-in.cpu_bytes;
gpu_left=Inf;
if request.gpu_bytes>0
    gpu_left=capacity(snapshot,'gpu_available')-o.gpu_reserve-in.gpu_bytes;
end
disk_left=Inf;
if disk_bytes>0
    disk_left=capacity(snapshot,'disk_available')-o.disk_reserve-in.disk_bytes;
end
ram_ok=isfinite(ram_left)&&ram_left>=request.cpu_bytes;
gpu_ok=~isnan(gpu_left)&&gpu_left>=request.gpu_bytes;
disk_ok=~isnan(disk_left)&&disk_left>=disk_bytes;
a=struct('ok',ram_ok&&gpu_ok&&disk_ok, ...
    'ram_headroom',ram_left-request.cpu_bytes, ...
    'gpu_headroom',gpu_left-request.gpu_bytes, ...
    'disk_headroom',disk_left-disk_bytes,'reason','ok');
if ~ram_ok
    a.reason='ram';
elseif ~gpu_ok
    a.reason='gpu';
elseif ~disk_ok
    a.reason='disk';
end
end
function value=capacity(s,field)
value=NaN;
if ~isfield(s,field),return;end
v=s.(field);
if isnumeric(v)&&isreal(v)&&isscalar(v)&&isfinite(v)&&v>=0
    value=double(v);
end
end
function tf=validBytes(x)
tf=isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x)&&x>=0;
end

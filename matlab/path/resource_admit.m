function a = resource_admit(snapshot,request,varargin)
%RESOURCE_ADMIT Check budgets, including in-flight reservations.
% a=resource_admit(snapshot,request,'ram_reserve',4*2^30,...
%   'gpu_reserve',1*2^30,'disk_reserve',0,'inflight',struct(...))
% All quantities bytes. Does not mutate state or acquire a system lock.
p=inputParser;
p.addParameter('ram_reserve',0,@nonnegativeScalar);
p.addParameter('gpu_reserve',0,@nonnegativeScalar);
p.addParameter('disk_reserve',0,@nonnegativeScalar);
p.addParameter('inflight',struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',0),@isstruct);
p.parse(varargin{:});
o=p.Results;
assert(isfield(request,'cpu_bytes')&&isfield(request,'gpu_bytes'), ...
    'resource_admit:Request','Request needs cpu_bytes and gpu_bytes.');
assert(nonnegativeScalar(request.cpu_bytes)&&nonnegativeScalar(request.gpu_bytes), ...
    'resource_admit:Request','Resource requests must be nonnegative finite bytes.');
disk_bytes=0;
if isfield(request,'disk_bytes'), disk_bytes=request.disk_bytes;end
assert(nonnegativeScalar(disk_bytes),'resource_admit:Request','Invalid disk request.');
in=o.inflight;
for k={'cpu_bytes','gpu_bytes','disk_bytes'}
    field=k{1};
    if ~isfield(in,field),in.(field)=0;end
    assert(nonnegativeScalar(in.(field)),'resource_admit:Inflight','Invalid reservation.');
end
ram_left=snapshot.ram_available-o.ram_reserve-in.cpu_bytes;
gpu_left=Inf;
if request.gpu_bytes>0
    gpu_left=snapshot.gpu_available-o.gpu_reserve-in.gpu_bytes;
end
disk_left=Inf;
if disk_bytes>0
    disk_left=snapshot.disk_available-o.disk_reserve-in.disk_bytes;
end
a=struct('ok',isfinite(ram_left)&&ram_left>=request.cpu_bytes && ...
    gpu_left>=request.gpu_bytes && disk_left>=disk_bytes, ...
    'ram_headroom',ram_left-request.cpu_bytes, ...
    'gpu_headroom',gpu_left-request.gpu_bytes, ...
    'disk_headroom',disk_left-disk_bytes,'reason','ok');
if isnan(ram_left)||ram_left<request.cpu_bytes
    a.reason='ram';
elseif isnan(gpu_left)||gpu_left<request.gpu_bytes
    a.reason='gpu';
elseif isnan(disk_left)||disk_left<disk_bytes
    a.reason='disk';
end
end
function tf=nonnegativeScalar(x)
tf=isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0;
end

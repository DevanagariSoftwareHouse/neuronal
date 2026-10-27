function [s,a] = resource_wait(request,varargin)
%RESOURCE_WAIT Cooperatively poll for available resources until timeout.
% [S,A]=RESOURCE_WAIT(REQUEST,'timeout',60,'poll',0.25,'gpu',false)
% Does NOT reserve memory or coordinate independent processes.
p=inputParser;p.PartialMatching=false;
p.addParameter('timeout',60,@nonnegative);
p.addParameter('poll',0.25,@positive);
p.addParameter('gpu',false,@(x)islogical(x)&&isscalar(x));
p.addParameter('disk_path','',@(x)ischar(x)||isstring(x));
p.addParameter('ram_reserve',0,@nonnegative);
p.addParameter('gpu_reserve',0,@nonnegative);
p.addParameter('disk_reserve',0,@nonnegative);
p.addParameter('inflight',struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',0), ...
    @(x)isstruct(x)&&isscalar(x));
p.parse(varargin{:});o=p.Results;
assert(isstruct(request)&&isscalar(request)&&isfield(request,'gpu_bytes'),...
    'resource_wait:Request','Request must provide gpu_bytes.');
assert(~(request.gpu_bytes>0&&~o.gpu),...
    'resource_wait:GPU','Set gpu=true for GPU requests.');
if isfield(request,'disk_bytes')&&request.disk_bytes>0&&isempty(char(o.disk_path))
    error('resource_wait:DiskPath','Set disk_path for disk requests.');
end
t=tic;
while true
    s=resource_snapshot('gpu',o.gpu,'disk_path',o.disk_path);
    a=resource_admit(s,request,'ram_reserve',o.ram_reserve, ...
        'gpu_reserve',o.gpu_reserve,'disk_reserve',o.disk_reserve, ...
        'inflight',o.inflight);
    if a.ok,return;end
    left=o.timeout-toc(t);
    if left<=0
        error('resource_wait:Timeout',...
            'Timed out waiting for %s (%.1f seconds).',a.reason,o.timeout);
    end
    pause(min(o.poll,left));
end
end
function tf=nonnegative(x)
tf=isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x)&&x>=0;
end
function tf=positive(x)
tf=nonnegative(x)&&x>0;
end

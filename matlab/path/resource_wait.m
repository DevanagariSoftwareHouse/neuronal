function [s,a] = resource_wait(request,varargin)
%RESOURCE_WAIT Cooperatively poll memory until admission or bounded timeout.
% [s,a]=resource_wait(req,'timeout',120,'poll',0.25,'gpu',false,...
%    'disk_path','/tmp','ram_reserve',4*2^30,'inflight',reservations)
% Do not call while holding storage locks. Does NOT reserve memory.
p=inputParser;
p.addParameter('timeout',60,@(x)isnumeric(x)&&isscalar(x)&&x>=0&&isfinite(x));
p.addParameter('poll',0.25,@(x)isnumeric(x)&&isscalar(x)&&x>0&&isfinite(x));
p.addParameter('gpu',false,@(x)islogical(x)&&isscalar(x));
p.addParameter('disk_path','',@(x)ischar(x)||isstring(x));
p.addParameter('ram_reserve',0,@(x)isnumeric(x)&&isscalar(x)&&x>=0);
p.addParameter('gpu_reserve',0,@(x)isnumeric(x)&&isscalar(x)&&x>=0);
p.addParameter('disk_reserve',0,@(x)isnumeric(x)&&isscalar(x)&&x>=0);
p.addParameter('inflight',struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',0),@isstruct);
p.parse(varargin{:});
o=p.Results;
assert(~(request.gpu_bytes>0 && ~o.gpu), ...
    'resource_wait:GPU','Set gpu=true for GPU requests.');
t=tic;
while true
    s=resource_snapshot('gpu',o.gpu,'disk_path',o.disk_path);
    a=resource_admit(s,request,'ram_reserve',o.ram_reserve, ...
        'gpu_reserve',o.gpu_reserve,'disk_reserve',o.disk_reserve,'inflight',o.inflight);
    if a.ok,return;end
    left=o.timeout-toc(t);
    if left<=0
        error('resource_wait:Timeout','Timed out waiting for %s (%.1f seconds).',a.reason,o.timeout);
    end
    pause(min(o.poll,left));
end
end

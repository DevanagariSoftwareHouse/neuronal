function [n,a] = resource_batch_size(snapshot,request,max_tasks,varargin)
%RESOURCE_BATCH_SIZE Max admissible concurrent identical tasks.
% Accounts for client-side in-flight reservations passed in varargin.
validateattributes(max_tasks,{'numeric'},{'scalar','integer','nonnegative','finite'});
n=0;
a=resource_admit(snapshot,request,varargin{:});
if ~a.ok || max_tasks==0,return;end
limits=max_tasks;
if request.cpu_bytes>0
    limits=min(limits,floor((a.ram_headroom+request.cpu_bytes)/request.cpu_bytes));
end
if request.gpu_bytes>0
    limits=min(limits,floor((a.gpu_headroom+request.gpu_bytes)/request.gpu_bytes));
end
if isfield(request,'disk_bytes') && request.disk_bytes>0
    limits=min(limits,floor((a.disk_headroom+request.disk_bytes)/request.disk_bytes));
end
n=max(0,min(max_tasks,limits));
end

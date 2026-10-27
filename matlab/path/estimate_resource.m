function e = estimate_resource(target,varargin)
%ESTIMATE_RESOURCE Estimate CPU/GPU working-memory needs for a planned task.
% E=ESTIMATE_RESOURCE(N,'precision','single','workspace_factor',12)
% E=ESTIMATE_RESOURCE(N,'precision','double','gpu',true)
% E=ESTIMATE_RESOURCE('filter_do',N,C,FD,'phase','causal')
% E=ESTIMATE_RESOURCE(@spike_interval_plan,S,U,W)
%
% Numeric TARGET estimates a generic N-sample pipeline (the historical
% RESOURCE_ESTIMATE model). A function name/handle dispatches to a
% function-specific model. For storage I/O, prefer STORAGE_ESTIMATE.
% Estimates are heuristics, not measured peaks or resource reservations.
narginchk(1,inf);
if isnumeric(target)
    e=generic_estimate(target,varargin{:});
else
    e=resource_estimate_function(target,varargin{:});
end
end

function e=generic_estimate(n_samples,varargin)
validateattributes(n_samples,{'numeric'},...
    {'scalar','real','finite','integer','nonnegative'});
p=inputParser;
p.PartialMatching=false;
p.addParameter('precision','double',@(x)textChoice(x,{'single','double'}));
p.addParameter('workspace_factor',12, ...
    @(x)isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x)&&x>=1);
p.addParameter('fixed_bytes',0, ...
    @(x)isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x)&&x>=0);
p.addParameter('gpu',false,@(x)islogical(x)&&isscalar(x));
p.parse(varargin{:});
o=p.Results;
b=8;
if strcmpi(char(o.precision),'single'),b=4;end
bytes=double(n_samples)*b*o.workspace_factor+o.fixed_bytes;
assert(isfinite(bytes),'estimate_resource:Overflow', ...
    'Estimated bytes exceed finite floating point capacity.');
bytes=ceil(bytes);
e=struct('task_bytes',bytes,'cpu_bytes',bytes, ...
    'gpu_bytes',0,'bytes_per_sample',b, ...
    'workspace_factor',o.workspace_factor);
if o.gpu
    % Generic model conservatively retains an equal-sized host workspace.
    e.gpu_bytes=bytes;
end
end

function tf=textChoice(x,values)
tf=(ischar(x)||isstring(x))&&isscalar(string(x))&& ...
    any(strcmpi(char(x),values));
end

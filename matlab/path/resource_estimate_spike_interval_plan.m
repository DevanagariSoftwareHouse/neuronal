function e = resource_estimate_spike_interval_plan(S,U,W,varargin)
%RESOURCE_ESTIMATE_SPIKE_INTERVAL_PLAN Estimate peak extra CPU bytes.
% S spikes, U units, W windows. Assumes TIMES and UNIT_INDEX already loaded.
% Includes retained per-unit times/sample/left/right arrays and temporary
% sorting/indexing buffers; input arrays not counted. Model is conservative.
validateattributes(S,{'numeric'},{'scalar','integer','nonnegative','finite'});
validateattributes(U,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(W,{'numeric'},{'scalar','integer','positive','finite'});
p=inputParser;p.addParameter('safety_factor',1.75,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=1);
p.parse(varargin{:});f=p.Results.safety_factor;
% Retained double timestamp/sample = 16*S, uint32 endpoints = 8*W*U,
% count matrix = 4*W*U, plus bounds and cell containers.
retained=16*double(S)+12*double(W)*double(U)+16*double(W)+4*8*double(U);
% Sorting, cumulative arrays, masks, lower-bound temporaries.
temporary=48*double(S)+80*double(W)+24*double(W)*double(U);
peak=ceil((retained+temporary)*f);
e=struct('cpu_bytes',peak,'gpu_bytes',0,'disk_bytes',0, ...
    'task_bytes',peak,'retained_output_bytes',ceil(retained), ...
    'safety_factor',f,'model','spike_interval_plan sorted index and window arrays', ...
    'confidence','heuristic','notes','Caller inputs are assumed resident on CPU.');
end

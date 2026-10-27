function e = resource_estimate(n_samples,varargin)
%RESOURCE_ESTIMATE Conservative bytes for one channel/band pipeline task.
% e=resource_estimate(N,'precision','double','workspace_factor',12,...
%    'fixed_bytes',0,'gpu',false)
% Empirical budgeting heuristic, NOT a verified FFT peak or allocation.
p=inputParser;
p.addParameter('precision','double',@(x)any(strcmpi(char(x),{'single','double'})));
p.addParameter('workspace_factor',12,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=1);
p.addParameter('fixed_bytes',0,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0);
p.addParameter('gpu',false,@(x)islogical(x)&&isscalar(x));
p.parse(varargin{:});
validateattributes(n_samples,{'numeric'},{'scalar','real','finite','integer','nonnegative'});
b=8;
if strcmpi(char(p.Results.precision),'single'),b=4;end
bytes=double(n_samples)*b*p.Results.workspace_factor + p.Results.fixed_bytes;
e=struct('task_bytes',ceil(bytes),'cpu_bytes',ceil(bytes), ...
    'gpu_bytes',0,'bytes_per_sample',b,'workspace_factor',p.Results.workspace_factor);
if p.Results.gpu
    % GPU pipeline still has host buffers; conservatively count both.
    e.gpu_bytes=ceil(bytes);
end
end

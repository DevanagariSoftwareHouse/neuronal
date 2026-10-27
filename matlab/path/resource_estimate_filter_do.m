function e = resource_estimate_filter_do(N,C,fd,varargin)
%RESOURCE_ESTIMATE_FILTER_DO Predict additional working set for FILTER_DO.
% e=resource_estimate_filter_do(N,C,fd,'precision','double', ...
%       'phase','zero','device','cpu','safety_factor',2)
% Assumes input X already exists; counts output and intermediate work buffers.
% SOS zero-phase FILTFILT internals are undocumented: this is a conservative
% model with a caller-calibratable safety factor, not a rigorous maximum.
validateattributes(N,{'numeric'},{'scalar','integer','nonnegative','finite'});
validateattributes(C,{'numeric'},{'scalar','integer','positive','finite'});
assert(isstruct(fd)&&isfield(fd,'form'),'Invalid filter design.');
p=inputParser;
p.addParameter('precision','double',@(x)any(strcmpi(char(x),{'single','double'})));
p.addParameter('phase','zero',@(x)any(strcmpi(char(x),{'zero','causal'})));
p.addParameter('device','cpu',@(x)any(strcmpi(char(x),{'cpu','gpu'})));
p.addParameter('safety_factor',2,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=1);
p.parse(varargin{:});o=p.Results;
b=8;if strcmpi(char(o.precision),'single'),b=4;end
sample=double(N)*double(C)*b;
sections=1;
if strcmpi(char(fd.form),'sos') && isfield(fd,'sos') && ~isempty(fd.sos)
    sections=size(fd.sos,1);
end
identity=isfield(fd,'kind')&&strcmp(fd.kind,'identity');
if identity
    peak=0;
else
    % FILTER_DO passes through multiple arrays; FILTFILT can allocate padding,
    % per-section and forward/backward workspaces. The coefficients add little.
    if strcmpi(char(o.phase),'zero')
        buffers=4+min(sections,16); % heuristic per-section allowance
    else
        buffers=2+min(sections,16);
    end
    peak=ceil(sample*buffers*o.safety_factor+sections*6*8);
end
cpu=peak;gpu=0;
if strcmpi(char(o.device),'gpu')
    assert(~strcmpi(char(o.phase),'zero'), ...
        'resource_estimate_filter_do:Unsupported', ...
        'filter_do does not support native zero-phase filtering on GPU.');
    gpu=peak;
    cpu=0;
end
e=struct('cpu_bytes',cpu,'gpu_bytes',gpu,'disk_bytes',0, ...
    'task_bytes',cpu+gpu,'persistent_input_bytes',sample, ...
    'safety_factor',o.safety_factor,'model','filter_do working arrays', ...
    'confidence','heuristic','notes', ...
    'Input is assumed allocated; CPU fallback of gpuArray must be budgeted separately.');
end

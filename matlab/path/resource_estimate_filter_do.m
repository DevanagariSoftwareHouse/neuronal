function e = resource_estimate_filter_do(N,C,fd,varargin)
%RESOURCE_ESTIMATE_FILTER_DO Additional FILTER_DO working memory estimate.
% E=RESOURCE_ESTIMATE_FILTER_DO(N,C,FD,'device','gpu','gpu_policy','cpu')
% Defaults match FILTER_DO: phase='causal', GPU input falls back to CPU.
% Input remains resident. Estimates are heuristics, NOT measured maxima.
validateattributes(N,{'numeric'},{'scalar','real','integer','nonnegative','finite'});
validateattributes(C,{'numeric'},{'scalar','real','integer','positive','finite'});
assert(isstruct(fd)&&isscalar(fd)&&isfield(fd,'form'),...
    'resource_estimate_filter_do:Design','Expected a scalar filter design.');
p=inputParser;p.PartialMatching=false;
p.addParameter('precision','double',@(x)choice(x,{'single','double'}));
p.addParameter('phase','causal',@(x)choice(x,{'causal','zero'}));
p.addParameter('device','cpu',@(x)choice(x,{'cpu','gpu'}));
p.addParameter('gpu_policy','cpu',@(x)choice(x,{'cpu','native','error'}));
p.addParameter('safety_factor',2,@(x)isnumeric(x)&&isreal(x)&&isscalar(x)&&isfinite(x)&&x>=1);
p.parse(varargin{:});o=p.Results;
on_gpu=strcmpi(char(o.device),'gpu');
policy=lower(char(o.gpu_policy));phase=lower(char(o.phase));
if on_gpu&&strcmp(policy,'error')
    error('resource_estimate_filter_do:Unsupported','GPU input is rejected.');
end
if on_gpu&&strcmp(policy,'native')&&strcmp(phase,'zero')
    error('resource_estimate_filter_do:Unsupported','Zero-phase native GPU is unsupported.');
end
form=lower(char(fd.form));
if ~any(strcmp(form,{'sos','ba'}))
    error('resource_estimate_filter_do:Design','Unsupported filter form.');
end
b=8;if strcmpi(char(o.precision),'single'),b=4;end
input_bytes=double(N)*double(C)*b;
assert(isfinite(input_bytes),'resource_estimate_filter_do:Size','Array too large.');
sections=1;
if strcmp(form,'sos')&&isfield(fd,'sos')&&~isempty(fd.sos)
    sections=size(fd.sos,1);
end
identity=isfield(fd,'kind')&&strcmpi(char(fd.kind),'identity');
cpu=0;gpu=0;transfer=0;
if ~identity&&input_bytes>0
    if strcmp(phase,'zero'),buffers=4+min(sections,16);
    else,buffers=2+min(sections,16);
    end
    peak=ceil((input_bytes*buffers+sections*6*8)*o.safety_factor);
    if ~on_gpu
        cpu=peak;
    elseif strcmp(policy,'native')
        gpu=peak;
    else
        % Gather input, filter on CPU, and allocate GPU output on re-upload.
        cpu=ceil(input_bytes+peak);
        gpu=ceil(input_bytes*o.safety_factor);
        transfer=2*input_bytes;
    end
end
e=struct('cpu_bytes',cpu,'gpu_bytes',gpu,'disk_bytes',0,...
    'task_bytes',cpu+gpu,'persistent_input_bytes',input_bytes,...
    'host_transfer_bytes',transfer,'safety_factor',o.safety_factor,...
    'model','filter_do additional buffers','confidence','heuristic',...
    'notes','GPU-to-CPU fallback needs host workspace and device output.');
end
function tf=choice(x,values)
tf=(ischar(x)||isstring(x))&&isscalar(string(x))&&any(strcmpi(char(x),values));
end

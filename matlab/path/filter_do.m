function y = filter_do(x, fs, fd, varargin)
%FILTER_DO Apply a FILTER_DESIGN specification to sample-by-channel data.
% Y = FILTER_DO(X,FS,FD) filters down dimension 1 (time).
% Y = FILTER_DO(...,'phase','causal'|'zero','gpu','cpu'|'native'|'error')
%
% GPU policy defaults to 'cpu': gather, filter on CPU, then restore gpuArray.
% 'native' attempts causal filtering on GPU without an implicit fallback.
% Zero-phase filtering requires CPU execution.
% Requires Signal Processing Toolbox for FILTFILT.
narginchk(3,inf);
if ~isstruct(fd) || ~isscalar(fd) || ~isfield(fd,'form')
    error('filter_do:Design','FD must be a FILTER_DESIGN scalar struct.');
end
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
if isfield(fd,'fs') && abs(double(fd.fs)-double(fs)) > 1e-10*max(1,double(fs))
    error('filter_do:FsMismatch','FS must agree with FD.fs.');
end
if ~isnumeric(x) || ~isreal(x)
    error('filter_do:Input','X must be a real numeric array.');
end
if isa(x,'gpuArray')
    precision = underlyingType(x);
else
    precision = class(x);
end
if ~any(strcmp(precision,{'single','double'}))
    error('filter_do:Precision','X must be single or double.');
end
if mod(numel(varargin),2)~=0
    error('filter_do:Options','Expected name-value option pairs.');
end
phase = 'causal';
gpuPolicy = 'cpu';
for k=1:2:numel(varargin)
    key=lower(char(varargin{k}));
    val=lower(char(varargin{k+1}));
    switch key
        case 'phase', phase=val;
        case 'gpu', gpuPolicy=val;
        otherwise, error('filter_do:Options','Unknown option %s.',key);
    end
end
if ~any(strcmp(phase,{'causal','zero'}))
    error('filter_do:Phase','Phase must be causal or zero.');
end
if ~any(strcmp(gpuPolicy,{'cpu','native','error'}))
    error('filter_do:Gpu','GPU policy must be cpu, native or error.');
end
onGpu=isa(x,'gpuArray');
if onGpu && strcmp(gpuPolicy,'error')
    error('filter_do:GPURejected','GPU input rejected.');
end
if onGpu && strcmp(gpuPolicy,'native') && strcmp(phase,'zero')
    error('filter_do:GPUZeroPhase','Use gpu=cpu for zero-phase filtering.');
end
% Identity filters are returned unchanged and avoid unnecessary transfers.
if isfield(fd,'kind') && strcmp(fd.kind,'identity')
    y=x;
    return;
end
if onGpu && strcmp(gpuPolicy,'cpu')
    x=gather(x);
end
if isempty(x)
    y=x;
elseif strcmp(fd.form,'sos')
    if ~isfield(fd,'sos') || ~isfield(fd,'gain') || isempty(fd.sos)
        error('filter_do:SOS','Missing SOS coefficients and gain.');
    end
    sos=double(fd.sos);
    gain=double(fd.gain);
    if size(sos,2)~=6 || any(~isfinite(sos(:))) || any(sos(:,4)==0) || ...
            ~isscalar(gain) || ~isfinite(gain)
        error('filter_do:SOS','Invalid SOS coefficients.');
    end
    if strcmp(phase,'zero')
        y=filtfilt(sos,gain,x);
    else
        y=x;
        for j=1:size(sos,1)
            b=sos(j,1:3)/sos(j,4);
            a=sos(j,4:6)/sos(j,4);
            try
                y=filter(b,a,y,[],1);
            catch ME
                if onGpu && strcmp(gpuPolicy,'native')
                    error('filter_do:NativeGPU','Native SOS GPU filtering failed: %s',ME.message);
                end
                rethrow(ME);
            end
        end
        y=y.*cast(gain,'like',y);
    end
elseif strcmp(fd.form,'ba')
    if ~isfield(fd,'b') || ~isfield(fd,'a') || isempty(fd.b) || isempty(fd.a)
        error('filter_do:BA','Missing numerator or denominator coefficients.');
    end
    b=double(fd.b);
    a=double(fd.a);
    if any(~isfinite(b(:))) || any(~isfinite(a(:))) || a(1)==0
        error('filter_do:BA','Invalid transfer function coefficients.');
    end
    if strcmp(phase,'zero')
        y=filtfilt(b,a,x);
    else
        try
            y=filter(b,a,x,[],1);
        catch ME
            if onGpu && strcmp(gpuPolicy,'native')
                error('filter_do:NativeGPU','Native GPU filtering failed: %s',ME.message);
            end
            rethrow(ME);
        end
    end
else
    error('filter_do:Form','Unsupported design form %s.',fd.form);
end
if onGpu && strcmp(gpuPolicy,'cpu')
    y=gpuArray(y);
end
end

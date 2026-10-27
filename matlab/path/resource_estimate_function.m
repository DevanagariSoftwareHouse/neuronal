function e = resource_estimate_function(name,varargin)
%RESOURCE_ESTIMATE_FUNCTION Dispatch function-specific resource estimates.
% E=RESOURCE_ESTIMATE_FUNCTION(@filter_do,N,C,FD,...)
% E=RESOURCE_ESTIMATE_FUNCTION('spike_interval_plan',S,U,W,...)
% E=RESOURCE_ESTIMATE_FUNCTION('spike_interval_features',N,S,U,W,...)
% E=RESOURCE_ESTIMATE_FUNCTION('storage_write',[N C],...)
% E=RESOURCE_ESTIMATE_FUNCTION('storage_read',[N C],...)
% Compatibility dispatcher for ESTIMATE_RESOURCE(name,...).
% Prefer STORAGE_ESTIMATE for storage operations.
% Results are heuristics; no memory or disk space is reserved.
if isa(name,'function_handle'),name=func2str(name);end
assert((ischar(name)||isstring(name))&&isscalar(string(name)),...
    'resource_estimate_function:Name','Expected a function name.');
switch lower(char(name))
    case 'filter_do'
        e=resource_estimate_filter_do(varargin{:});
    case 'spike_interval_plan'
        e=resource_estimate_spike_interval_plan(varargin{:});
    case 'spike_interval_features'
        e=resource_estimate_spike_interval_features(varargin{:});
    case 'storage_write'
        e=storage_estimate('write',varargin{:});
    case 'storage_read'
        e=storage_estimate('read',varargin{:});
    otherwise
        error('resource_estimate_function:Unknown',...
            'No estimator for %s. Add resource_estimate_<function>.m.',char(name));
end
end

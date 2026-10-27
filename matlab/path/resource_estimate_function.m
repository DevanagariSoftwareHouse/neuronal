function e = resource_estimate_function(name,varargin)
%RESOURCE_ESTIMATE_FUNCTION Estimate additional peak working memory for a function.
% e = resource_estimate_function('filter_do',N,C,fd,'precision','double',...)
% e = resource_estimate_function('spike_interval_plan',S,U,W,...)
% e = resource_estimate_function('spike_interval_features',N,S,U,W,...)
% Memory estimates are planning heuristics, NOT measurements/reservations.
% The input arrays are assumed resident on the chosen device already.
% Outputs use resource_admit-compatible cpu_bytes/gpu_bytes fields.
if isa(name,'function_handle'), name=func2str(name); end
switch lower(char(name))
    case 'filter_do'
        e=resource_estimate_filter_do(varargin{:});
    case 'spike_interval_plan'
        e=resource_estimate_spike_interval_plan(varargin{:});
    case 'spike_interval_features'
        e=resource_estimate_spike_interval_features(varargin{:});
    otherwise
        error('resource_estimate_function:Unknown', ...
            'No calibrated estimator for %s. Add a resource_estimate_<function>.m.',char(name));
end
end

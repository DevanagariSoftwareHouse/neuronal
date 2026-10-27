function e = estimate_resource(name,varargin)
%ESTIMATE_RESOURCE Public shorthand for function-specific memory estimates.
% E=ESTIMATE_RESOURCE('filter_do',N,C,FD,'phase','causal')
% E=ESTIMATE_RESOURCE(@storage_write,[100000 16],...
%       'precision','int16','backend','binary')
% Fields cpu_bytes/gpu_bytes/disk_bytes are compatible with RESOURCE_ADMIT.
% No estimate is a memory reservation or a guaranteed peak.
narginchk(1,inf);
e=resource_estimate_function(name,varargin{:});
end

function e = resource_estimate(n_samples,varargin)
%RESOURCE_ESTIMATE Compatibility alias; prefer ESTIMATE_RESOURCE.
% E=RESOURCE_ESTIMATE(N,'precision','single','workspace_factor',12)
% Preserves the original generic sample-count estimate and output fields.
% New work should call ESTIMATE_RESOURCE(N,...) instead.
e=estimate_resource(n_samples,varargin{:});
end

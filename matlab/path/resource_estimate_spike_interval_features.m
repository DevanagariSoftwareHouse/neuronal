function e = resource_estimate_spike_interval_features(N,S,U,W,varargin)
%RESOURCE_ESTIMATE_SPIKE_INTERVAL_FEATURES Estimate extra CPU memory peak.
% N = full analytic signal samples, S = total mapped spikes, U = units,
% W = windows. Assumes plan and analytic_signal are already resident.
% Feature output W-by-U: 3 singles + 1 uint32 = 16*W*U bytes.
validateattributes(N,{'numeric'},{'scalar','integer','nonnegative','finite'});
validateattributes(S,{'numeric'},{'scalar','integer','nonnegative','finite'});
validateattributes(U,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(W,{'numeric'},{'scalar','integer','positive','finite'});
p=inputParser;p.addParameter('max_unit_spikes',S,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0&&x<=S);
p.addParameter('safety_factor',1.75,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=1);
p.parse(varargin{:});o=p.Results;
% Internally processes one unit at a time. Worst per-unit transient
% includes h/amp/valid/c/s/a/prefix arrays and endpoint computations.
% O(Smax+W) rather than O(S*W). FFT/Hilbert not included.
output=16*double(W)*double(U);
working=120*double(o.max_unit_spikes)+160*double(W);
peak=ceil((output+working)*o.safety_factor);
e=struct('cpu_bytes',peak,'gpu_bytes',0,'disk_bytes',0, ...
    'task_bytes',peak,'retained_output_bytes',ceil(output), ...
    'safety_factor',o.safety_factor,'model','spike_interval_features prefix sums', ...
    'confidence','heuristic','notes', ...
    'Excludes full analytic signal and plan, which caller must reserve separately.');
end

function test_resource_estimate_function()
% Self-contained estimate tests; MATLAB R2019a, no GPU required.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'path'));
fd=struct('form','sos','kind','bandpass','sos',ones(2,6));
a=resource_estimate_function('filter_do',1000,2,fd);
assert(a.cpu_bytes>0 && a.gpu_bytes==0);
b=resource_estimate_function('spike_interval_plan',10000,88,127);
assert(b.cpu_bytes>b.retained_output_bytes);
c=resource_estimate_function('spike_interval_features',1e6,10000,88,127);
assert(c.cpu_bytes>=c.retained_output_bytes);
assert(resource_estimate_function('filter_do',0,1,fd).cpu_bytes>=0);
try
    resource_estimate_function('unknown_function',100);
    error('Expected failure for unknown estimator');
catch ME
    assert(strcmp(ME.identifier,'resource_estimate_function:Unknown'));
end
fprintf('test_resource_estimate_function: PASS\n');
end

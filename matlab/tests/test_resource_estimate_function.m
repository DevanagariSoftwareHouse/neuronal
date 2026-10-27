function test_resource_estimate_function()
%TEST_RESOURCE_ESTIMATE_FUNCTION No GPU hardware required; MATLAB R2019a.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'path'));
fd=struct('form','sos','kind','bandpass','sos',ones(2,6));
a=estimate_resource(@filter_do,1000,2,fd);
assert(a.cpu_bytes>0&&a.gpu_bytes==0&&a.disk_bytes==0);
assert(strcmp(a.confidence,'heuristic'));
b=estimate_resource('spike_interval_plan',10000,88,127);
assert(b.cpu_bytes>b.retained_output_bytes);
c=estimate_resource('spike_interval_features',1e6,10000,88,127);
assert(c.cpu_bytes>=c.retained_output_bytes);
assert(resource_estimate_function('filter_do',0,1,fd).cpu_bytes>=0);
native=estimate_resource('filter_do',1000,2,fd,...
    'device','gpu','gpu_policy','native');
assert(native.cpu_bytes==0&&native.gpu_bytes>0);
fallback=estimate_resource('filter_do',1000,2,fd,...
    'device','gpu','gpu_policy','cpu','phase','zero');
assert(fallback.cpu_bytes>0&&fallback.gpu_bytes>0);
assert(fallback.host_transfer_bytes==2*fallback.persistent_input_bytes);
try
    estimate_resource('filter_do',1000,2,fd,...
        'device','gpu','gpu_policy','native','phase','zero');
    error('test_resource_estimate_function:Expected','Expected rejection.');
catch ME
    assert(strcmp(ME.identifier,'resource_estimate_filter_do:Unsupported'));
end
identity=fd;identity.kind='identity';
z=estimate_resource('filter_do',1000,2,identity);
assert(z.cpu_bytes==0&&z.gpu_bytes==0&&z.task_bytes==0);
w=estimate_resource('storage_write',[1000 4],...
    'precision','int16','backend','binary');
assert(w.payload_bytes==8000&&w.disk_bytes>=w.payload_bytes);
assert(w.cpu_bytes>0&&w.gpu_bytes==0);
rd=estimate_resource('storage_read',[1000 4],...
    'precision','int16','backend','binary','range_rows',[10 109]);
assert(rd.retained_output_bytes==800&&rd.disk_bytes==0);
mat=estimate_resource('storage_read',[1000 4],...
    'precision','int16','backend','mat','mat_version','-v7',...
    'range_rows',[10 109]);
assert(mat.cpu_bytes>rd.cpu_bytes);
try
    estimate_resource('storage_read',[100 2],'range_rows',[101 110]);
    error('test_resource_estimate_function:Expected','Expected invalid range.');
catch ME
    assert(strcmp(ME.identifier,'resource_estimate_storage_io:Range'));
end
try
    resource_estimate_function('unknown_function',100);
    error('test_resource_estimate_function:Expected','Expected unknown function.');
catch ME
    assert(strcmp(ME.identifier,'resource_estimate_function:Unknown'));
end
fprintf('test_resource_estimate_function: PASS\n');
end

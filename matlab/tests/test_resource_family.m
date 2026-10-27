function test_resource_family()
%TEST_RESOURCE_FAMILY Resource admission and waiting; no GPU needed.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'path'));
s=resource_snapshot('gpu',false,'disk_path',tempdir);
assert(s.ram_available>0&&s.ram_total>=s.ram_available);
e=resource_estimate(1000,'precision','single','workspace_factor',12);
assert(e.cpu_bytes==48000&&e.gpu_bytes==0);
g=resource_estimate(1000,'gpu',true);assert(g.gpu_bytes==g.cpu_bytes);
fake=struct('ram_available',1000,'gpu_available',500,'disk_available',2000);
r=struct('cpu_bytes',200,'gpu_bytes',100,'disk_bytes',300);
a=resource_admit(fake,r,'ram_reserve',100,'gpu_reserve',100);
assert(a.ok&&strcmp(a.reason,'ok'));
[n,~]=resource_batch_size(fake,r,10,'ram_reserve',100,'gpu_reserve',100);
assert(n==4);
a=resource_admit(fake,r,'inflight',...
    struct('cpu_bytes',850,'gpu_bytes',0,'disk_bytes',0));
assert(~a.ok&&strcmp(a.reason,'ram'));
a=resource_admit(fake,r,'inflight',...
    struct('cpu_bytes',0,'gpu_bytes',450,'disk_bytes',0));
assert(~a.ok&&strcmp(a.reason,'gpu'));
a=resource_admit(fake,r,'inflight',...
    struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',1800));
assert(~a.ok&&strcmp(a.reason,'disk'));
unknown=resource_admit(struct('ram_available',NaN,...
    'gpu_available',NaN,'disk_available',NaN),r);
assert(~unknown.ok&&strcmp(unknown.reason,'ram'));
assert(strcmp(resource_admit(rmfield(fake,'gpu_available'),r).reason,'gpu'));
assert(strcmp(resource_admit(rmfield(fake,'disk_available'),r).reason,'disk'));
cpu_only=struct('cpu_bytes',1,'gpu_bytes',0);
assert(resource_admit(struct('ram_available',20),cpu_only).ok);
try
    resource_admit(fake,struct('cpu_bytes',-1,'gpu_bytes',0));
    error('test_resource_family:Expected','Expected invalid request.');
catch ME
    assert(strcmp(ME.identifier,'resource_admit:Request'));
end
try
    resource_wait(r,'timeout',0,'gpu',false);
    error('test_resource_family:Expected','Expected GPU rejection.');
catch ME
    assert(strcmp(ME.identifier,'resource_wait:GPU'));
end
try
    resource_wait(struct('cpu_bytes',1,'gpu_bytes',0,'disk_bytes',1),...
        'timeout',0);
    error('test_resource_family:Expected','Expected missing disk path rejection.');
catch ME
    assert(strcmp(ME.identifier,'resource_wait:DiskPath'));
end
disp('test_resource_family: PASS');
end

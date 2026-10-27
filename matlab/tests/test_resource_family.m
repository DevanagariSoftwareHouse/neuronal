function test_resource_family()
%TEST_RESOURCE_FAMILY Lightweight tests; no GPU required (R2019a).
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'path'));
s=resource_snapshot('gpu',false,'disk_path',tempdir);
assert(s.ram_available>0 && s.ram_total>=s.ram_available);
e=resource_estimate(1000,'precision','single','workspace_factor',12);
assert(e.cpu_bytes==48000 && e.gpu_bytes==0);
g=resource_estimate(1000,'gpu',true);
assert(g.gpu_bytes==g.cpu_bytes);
fake=struct('ram_available',1000,'gpu_available',500,'disk_available',2000);
r=struct('cpu_bytes',200,'gpu_bytes',100,'disk_bytes',300);
a=resource_admit(fake,r,'ram_reserve',100,'gpu_reserve',100);
assert(a.ok);
[n,~]=resource_batch_size(fake,r,10,'ram_reserve',100,'gpu_reserve',100);
assert(n==4);
a=resource_admit(fake,r,'inflight',struct('cpu_bytes',850,'gpu_bytes',0,'disk_bytes',0));
assert(~a.ok && strcmp(a.reason,'ram'));
unknown=resource_admit(struct('ram_available',NaN,'gpu_available',NaN,'disk_available',NaN),r);
assert(~unknown.ok);
disp('test_resource_family: PASS');
end

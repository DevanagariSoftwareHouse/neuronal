function result = storage_benchmark(st,varargin)
%STORAGE_BENCHMARK Isolated write/full-read/window-read throughput probe.
% R=storage_benchmark(ST,'samples',1000000,'channels',4,'repeats',3).
% Creates an isolated temporary store under ST.root, verifies exact values,
% and removes it even after failure. Includes metadata/catalog overhead.
% OS caches are NOT cleared. Results are not cold-disk throughput claims.
st=storage_validate(st);
if st.readonly, error('storage:Readonly','Benchmark requires a writable root.'); end
p=inputParser; p.PartialMatching=false;
positive=@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=1&&x==fix(x);
addParameter(p,'samples',100000,positive); addParameter(p,'channels',2,positive);
addParameter(p,'repeats',3,positive); parse(p,varargin{:}); opt=p.Results;
root=tempname(st.root); cleanup=onCleanup(@()clean(root)); %#ok<NASGU>
cfg=st; cfg.root=root; cfg.create_parents=true; cfg.overwrite=true;
names=fieldnames(cfg); args={};
for k=1:numel(names)
    if ~strcmp(names{k},'backend'), args(end+1:end+2)={names{k},cfg.(names{k})}; end %#ok<AGROW>
end
probe=storage_create(st.backend,args{:});
x=reshape(single(mod(0:opt.samples*opt.channels-1,1024)),opt.samples,opt.channels);
if strcmp(st.precision,'double'), x=double(x); end
w=whos('x'); result=struct('backend',st.backend,'array_bytes',w.bytes, ...
    'write_seconds',zeros(opt.repeats,1),'read_seconds',zeros(opt.repeats,1), ...
    'window_seconds',zeros(opt.repeats,1));
range=[max(1,floor(opt.samples/2)) min(opt.samples,max(1,floor(opt.samples/2))+1023)];
for r=1:opt.repeats
    t=tic; storage_write(probe,'benchmark',x); result.write_seconds(r)=toc(t);
    t=tic; y=storage_read(probe,'benchmark'); result.read_seconds(r)=toc(t);
    assert(isequal(x,y),'storage:Benchmark','Round-trip mismatch.');
    t=tic; z=storage_read(probe,'benchmark',range); result.window_seconds(r)=toc(t);
    assert(isequal(z,x(range(1):range(2),:)),'storage:Benchmark','Range mismatch.');
end
info=storage_info(probe,'benchmark'); result.payload_bytes=info.bytes;
result.write_MiB_s=(w.bytes/2^20)./result.write_seconds;
result.read_MiB_s=(w.bytes/2^20)./result.read_seconds;
result.cache_policy='warm OS cache; no cache eviction';
end
function clean(root)
if isfolder(root), rmdir(root,'s'); end
end

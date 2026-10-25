function test_storage_family
%TEST_STORAGE_FAMILY Persistence contracts, including failure behavior.
root=tempname; mkdir(root); cleanup=onCleanup(@()rmdir(root,'s')); %#ok<NASGU>
backends={'hdf5','binary','mat'};
if exist('sqlite','file')==2 && license('test','Database_Toolbox')
    backends=[backends {'sqlite','hybrid'}];
else
    fprintf('SKIP SQLite/hybrid runtime: Database Toolbox unavailable.\n');
end
for b=1:numel(backends)
    backend=backends{b}; constructor=str2func(['storage_' backend]);
    st=constructor('root',fullfile(root,backend));
    key=storage_key('session','18','area','lfp_1','channel',3,'frequency',7);
    assert(strcmp(key,'session_18/lfp_1/ch_0003/frequency_0007'));
    classes={'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64','logical'};
    for c=1:numel(classes)
        x=cast(reshape(mod(0:119,91),[10 4 3]),classes{c});
        if strcmp(classes{c},'int64'), x(1)=intmax('int64'); end
        if strcmp(classes{c},'uint64'), x(1)=intmax('uint64'); end
        k=[key '/' classes{c}];
        storage_write(st,k,x,'metadata',struct('fs',500,'note','unit test'));
        assert(storage_exists(st,k));
        assert(isequal(storage_read(st,k),x));
        assert(isequal(storage_read(st,k,[3 7]),x(3:7,:,:)));
        info=storage_info(st,k);
        assert(strcmp(info.class,classes{c}) && isequal(info.size,size(x)));
        assert(info.metadata.fs==500 && info.bytes>0);
        must_fail(@()storage_write(st,k,x),'storage:Exists');
        must_fail(@()storage_read(st,k,[0 2]),'');
        must_fail(@()storage_read(st,k,[1 11]),'storage:Range');
        storage_append(st,k,x(1:2,:,:));
        assert(isequal(storage_read(st,k),cat(1,x,x(1:2,:,:))));
        ro=st; ro.readonly=true;
        assert(isequal(storage_read(ro,k,[1 2]),x(1:2,:,:)));
        must_fail(@()storage_delete(ro,k),'storage:Readonly');
        must_fail(@()storage_append(ro,k,x),'storage:Readonly');
        overwrite=st; overwrite.overwrite=true;
        storage_write(overwrite,k,x);
        assert(isequal(storage_read(st,k),x));
    end
    keys=storage_list(st,'session_18'); assert(numel(keys)==numel(classes));
    assert(isempty(storage_list(st,'session_1')));
    storage_write(st,'row',single(1:5));
    assert(isequal(storage_read(st,'row',[1 1]),single(1:5)));
    must_fail(@()storage_read(st,'row',[1 2]),'storage:Range');
    must_fail(@()storage_append(st,'row',single([1 2])),'storage:Append');
    ro=constructor('root',st.root,'readonly',true); assert(storage_exists(ro,'row'));
    other=st; other.backend='binary'; if strcmp(backend,'binary'), other.backend='mat'; end
    must_fail(@()storage_exists(other,'row'),'storage:Config');
    for k=1:numel(keys), storage_delete(st,keys{k}); end
    assert(isequal(storage_list(st),{'row'}));
    storage_delete(st,'row'); assert(~storage_exists(st,'row'));
    must_fail(@()storage_read(st,'row'),'storage:Missing');
    assert(isempty(storage_list(st)));
    storage_flush(st); storage_close(st); storage_close(st);
    caps=storage_capabilities(st); assert(~caps.streaming_append && ~caps.concurrent_write);
    r=storage_benchmark(st,'samples',31,'channels',2,'repeats',1);
    assert(r.array_bytes==31*2*4 && isempty(storage_list(st)));
    fprintf('PASS storage_%s\n',backend);
end
% Binary endian behavior and zero-sized arrays.
st=storage_binary('root',fullfile(root,'big-endian'),'byte_order','ieee-be');
x=uint16([1 256; 65535 7]); storage_write(st,'x',x);
assert(isequal(storage_read(st,'x',[2 2]),x(2,:)));
p=storage_path(st,'x'); fid=fopen(p.data,'r'); bytes=fread(fid,2,'*uint8'); fclose(fid);
assert(isequal(bytes,uint8([0;1])));
storage_write(st,'empty',zeros(0,3,'single'));
assert(isequal(storage_read(st,'empty'),zeros(0,3,'single')));
% MAT records, complex arrays, and the R2019a v7 policy.
st=storage_mat('root',fullfile(root,'records'));
r=struct('text','sample','count',bitshift(uint64(1),54));
storage_write(st,'record',r); assert(isequal(storage_read(st,'record'),r));
x=complex(rand(4,2),rand(4,2)); storage_write(st,'complex',x);
assert(isequal(storage_read(st,'complex',[2 3]),x(2:3,:)));
v7=storage_mat('root',fullfile(root,'v7'),'mat_version','-v7','mat_compression',true);
storage_write(v7,'x',x); assert(isequal(storage_read(v7,'x',[2 3]),x(2:3,:)));
% Explicit conversion, compression, and failed overwrite leaves old artifact.
st=storage_hdf5('root',fullfile(root,'compressed'),'compression',1,'chunk_samples',3,'precision','single');
storage_write(st,'x',ones(7,2)); info=storage_info(st,'x');
assert(strcmp(info.class,'single') && isequal(info.chunk_size,[3 1]));
st.overwrite=true;
must_fail(@()storage_write(st,'x',complex(ones(7,2),ones(7,2))),'storage:Type');
assert(isequal(storage_read(st,'x'),ones(7,2,'single')));
assert(~isfolder(fullfile(st.root,'.storage-write-lock')));
must_fail(@()storage_write(st,'empty',[]),'storage:Type');
assert(~storage_exists(st,'empty'));
% Safe keys, unknown options, read-only missing roots and configuration errors.
bad={'../escape','/absolute','a//b','a/../b','a\\b','a.store/b','a/metadata.store'};
for k=1:numel(bad), must_fail(@()storage_key(bad{k}),'storage:Key'); end
must_fail(@()storage_create('hdf5','chunk_samples',0),'');
must_fail(@()storage_create('hdf5','unknown',0),'');
must_fail(@()storage_create('mat','mat_version','-v7'),'storage:Config');
must_fail(@()storage_create('hdf5','root',fullfile(root,'missing'),'readonly',true),'storage:MissingRoot');
if any(strcmp(backends,'hybrid'))
    st=storage_hybrid('root',fullfile(root,'hybrid-bin'),'array_backend','binary');
    storage_write(st,'x',int16(1:5)); assert(isequal(storage_read(st,'x'),int16(1:5)));
    assert(isequal(storage_list(st),{'x'}));
end
fprintf('All available storage contracts passed.\n');
end
function must_fail(f,id)
try
    f();
catch err
    if ~isempty(id), assert(strcmp(err.identifier,id),'Unexpected error: %s (%s)',err.message,err.identifier); end
    return;
end
error('storage:Test','Expected an error: %s',id);
end

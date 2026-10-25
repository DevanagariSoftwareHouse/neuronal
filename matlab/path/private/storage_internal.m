function out = storage_internal(action,st,varargin)
%STORAGE_INTERNAL Shared implementation; public entry points enforce contract.
st=storage_validate(st); out=[];
if strcmp(action,'initialize'), initialize(st); return; end
verify_root(st);
switch action
    case 'exists'
        key=storage_key(varargin{1}); p=storage_path(st,key);
        out=isfile(p.metadata) && isfile(p.data);
        if out && indexed(st)
            db=open_db(st); guard=onCleanup(@()close(db)); %#ok<NASGU>
            rows=fetch(db,['SELECT key FROM artifacts WHERE key=' quote(key)]);
            out=~isempty(rows);
        end
    case 'info'
        key=storage_key(varargin{1}); require(st,key); p=storage_path(st,key);
        m=load(p.metadata,'info'); out=m.info;
    case 'read'
        key=storage_key(varargin{1}); info=storage_internal('info',st,key);
        p=storage_path(st,key); range=[];
        if numel(varargin)>2, error('storage:Arguments','Expected at most one row range.'); end
        if numel(varargin)==2
            range=varargin{2};
            validateattributes(range,{'numeric'},{'vector','numel',2,'real','finite','integer','positive'});
            range=double(range(:)');
            if range(2)<range(1) || range(2)>info.size(1)
                error('storage:Range','Range must be inclusive and within the first dimension.');
            end
        end
        out=read_payload(p,info,range);
    case 'list'
        if numel(varargin)>1, error('storage:Arguments','Expected at most one prefix.'); end
        prefix=''; if ~isempty(varargin), prefix=storage_key(varargin{1}); end
        if indexed(st)
            db=open_db(st); guard=onCleanup(@()close(db)); %#ok<NASGU>
            rows=fetch(db,'SELECT key FROM artifacts ORDER BY key');
            if istable(rows), rows=table2cell(rows); end
            out=rows(:,1); if isempty(rows), out=cell(0,1); end
        else
            entries=dir(fullfile(st.root,'artifacts','**','metadata.mat'));
            out=cell(numel(entries),1); base=fullfile(st.root,'artifacts');
            for k=1:numel(entries)
                rel=entries(k).folder(numel(base)+2:end);
                out{k}=strrep(rel(1:end-6),filesep,'/'); % strip .store
            end
            out=sort(out);
        end
        if ~isempty(prefix)
            out=out(strcmp(out,prefix) | strncmp(out,[prefix '/'],numel(prefix)+1));
        end
    case {'write','append','delete'}
        writable(st); lock=writer_lock(st); %#ok<NASGU>
        key=storage_key(varargin{1}); p=storage_path(st,key);
        exists=storage_internal('exists',st,key);
        if strcmp(action,'delete')
            require(st,key); publish(st,key,p,'',[],true); return;
        end
        x=varargin{2}; metadata=struct();
        if strcmp(action,'append')
            require(st,key); old=storage_internal('read',st,key);
            oldinfo=storage_internal('info',st,key); metadata=oldinfo.metadata;
            if ~strcmp(class(old),class(x)) || issparse(x) || isa(x,'gpuArray')
                error('storage:Append','Append requires the stored CPU class and dense input.');
            end
            a=size(old); b=size(x); n=max(numel(a),numel(b)); a(end+1:n)=1; b(end+1:n)=1;
            if ~isequal(a(2:end),b(2:end)), error('storage:Append','Trailing dimensions must match.'); end
            x=cat(1,old,x);
        else
            if exists && ~st.overwrite, error('storage:Exists','Key already exists: %s',key); end
            parser=inputParser; parser.PartialMatching=false;
            addParameter(parser,'metadata',struct(),@(v)isstruct(v)&&isscalar(v));
            parse(parser,varargin{3:end}); metadata=parser.Results.metadata;
        end
        if isa(x,'gpuArray'), error('storage:GPU','Call gather explicitly before storage_write.'); end
        if ~strcmp(st.precision,'preserve')
            if ~isnumeric(x), error('storage:Type','Precision conversion requires numeric input.'); end
            x=cast(x,st.precision);
        end
        if ~(isnumeric(x)||islogical(x)||isstruct(x)||iscell(x)||ischar(x)||isstring(x)) || issparse(x)
            error('storage:Type','Supported data: dense arrays, or MAT records/cells/text.');
        end
        stage=tempname(st.root); [ok,msg]=mkdir(stage);
        if ~ok, error('storage:IO','%s',msg); end
        cleanup=onCleanup(@()remove_dir(stage)); %#ok<NASGU>
        staged=p; staged.artifact=stage; [~,name,ext]=fileparts(p.data);
        staged.data=fullfile(stage,[name ext]); staged.metadata=fullfile(stage,'metadata.mat');
        info=write_payload(st,staged,x);
        info.key=key; info.metadata=metadata; info.schema_version=1;
        info.created_at=datestr(now,30); % wall-clock timestamp, not used for ordering
        info.timestamp_timezone='local';
        save(staged.metadata,'info','-v7');
        publish(st,key,p,stage,info,false);
    otherwise
        error('storage:Internal','Unknown operation.');
end
end

function initialize(st)
marker=fullfile(st.root,'storage_config.mat');
if isfile(marker), verify_root(st); return; end
writable(st); lock=writer_lock(st); %#ok<NASGU>
if isfile(marker), verify_root(st); return; end
identity=identity_of(st); %#ok<NASGU>
if indexed(st)
    path=fullfile(st.root,'catalog.sqlite');
    if isfile(path), db=sqlite(path,'connect'); else, db=sqlite(path,'create'); end
    guard=onCleanup(@()close(db)); %#ok<NASGU>
    exec(db,['CREATE TABLE IF NOT EXISTS artifacts (' ...
        'key TEXT PRIMARY KEY, backend TEXT NOT NULL, class TEXT NOT NULL,' ...
        'shape TEXT NOT NULL, bytes REAL NOT NULL, metadata TEXT NOT NULL)']);
end
tmp=[tempname(st.root) '.mat']; cleanup=onCleanup(@()remove_file(tmp)); %#ok<NASGU>
save(tmp,'identity','-v7'); checked_move(tmp,marker);
end

function id=identity_of(st)
id=struct('schema_version',1,'backend',st.backend,'array_backend','');
if strcmp(st.backend,'hybrid'), id.array_backend=st.array_backend; end
end

function verify_root(st)
f=fullfile(st.root,'storage_config.mat');
if ~isfile(f), error('storage:MissingRoot','Initialize the root with storage_create first.'); end
m=load(f,'identity');
if ~isfield(m,'identity') || ~isequal(m.identity,identity_of(st))
    error('storage:Config','Storage root belongs to a different backend or schema.');
end
end

function tf=indexed(st)
tf=any(strcmp(st.backend,{'sqlite','hybrid'}));
end

function writable(st)
if st.readonly, error('storage:Readonly','Storage is readonly.'); end
end

function guard=writer_lock(st)
% mkdir via Java returns false if already present (unlike MATLAB mkdir).
p=fullfile(st.root,'.storage-write-lock'); f=java.io.File(p);
if ~f.mkdir()
    error('storage:Locked','Another writer or a stale lock exists: %s',p);
end
guard=onCleanup(@()remove_dir(p));
end

function require(st,key)
if ~storage_internal('exists',st,key), error('storage:Missing','Missing artifact: %s',key); end
end

function db=open_db(st)
p=fullfile(st.root,'catalog.sqlite');
if ~isfile(p), error('storage:Catalog','Missing SQLite catalog.'); end
if st.readonly, db=sqlite(p,'readonly'); else, db=sqlite(p,'connect'); end
try
    exec(db,sprintf('PRAGMA busy_timeout = %d',st.busy_timeout_ms));
catch err
    close(db); rethrow(err);
end
end

function s=quote(s)
s=['''' strrep(char(s),'''','''''') ''''];
end

function info=write_payload(st,p,x)
info=struct('backend',p.backend,'class',class(x),'size',size(x), ...
    'bytes',0,'byte_order',st.byte_order,'mat_version',st.mat_version, ...
    'chunk_size',[],'compression',0,'is_real',isreal(x));
switch p.backend
    case 'hdf5'
        allowed={'double','single','int8','uint8','int16','uint16','int32','uint32','int64','uint64','logical'};
        if ~any(strcmp(class(x),allowed)) || ~isreal(x) || isempty(x)
            error('storage:Type','HDF5 requires a nonempty real dense numeric/logical array.');
        end
        shape=size(x); chunk=ones(size(shape)); chunk(1)=min(shape(1),st.chunk_samples);
        type=class(x); if islogical(x), type='uint8'; end
        args={'Datatype',type,'ChunkSize',chunk};
        if st.compression>0, args=[args {'Deflate',st.compression}]; end
        h5create(p.data,'/data',shape,args{:});
        h5write(p.data,'/data',cast(x,type));
        info.chunk_size=chunk; info.compression=st.compression;
    case 'binary'
        if ~(isnumeric(x)||islogical(x)) || ~isreal(x)
            error('storage:Type','Binary requires real dense numeric/logical arrays.');
        end
        fid=fopen(p.data,'w',st.byte_order);
        if fid<0, error('storage:IO','Cannot open binary output.'); end
        guard=onCleanup(@()fclose(fid));
        type=class(x); if islogical(x), type='uint8'; end
        count=fwrite(fid,x,type);
        if count~=numel(x), error('storage:IO','Short binary write.'); end
        clear guard;
    case 'mat'
        args={st.mat_version};
        if ~st.mat_compression, args{end+1}='-nocompression'; end
        save(p.data,'x',args{:});
end
d=dir(p.data); info.bytes=d.bytes;
end

function x=read_payload(p,info,range)
shape=info.size; count=shape; start=ones(size(shape));
if ~isempty(range), start(1)=range(1); count(1)=range(2)-range(1)+1; end
switch p.backend
    case 'hdf5'
        x=h5read(p.data,'/data',start,count);
        if strcmp(info.class,'logical'), x=logical(x); end
        x=reshape(x,count);
    case 'binary'
        types={'int8','uint8','logical','int16','uint16','int32','uint32','single','int64','uint64','double'};
        widths=[1 1 1 2 2 4 4 4 8 8 8]; width=widths(strcmp(types,info.class));
        if isempty(width), error('storage:Corrupt','Invalid binary class metadata.'); end
        fid=fopen(p.data,'r',info.byte_order);
        if fid<0, error('storage:IO','Cannot open binary input.'); end
        guard=onCleanup(@()fclose(fid)); %#ok<NASGU>
        type=info.class; if strcmp(type,'logical'), type='uint8'; end
        if isempty(range)
            [x,n]=fread(fid,prod(shape),['*' type]);
            if n~=prod(shape), error('storage:Corrupt','Truncated binary payload.'); end
            if strcmp(info.class,'logical'), x=logical(x); end
            x=reshape(x,shape); return;
        end
        x=zeros(count,info.class);
        ncols=prod(shape(2:end));
        for col=1:ncols
            offset=((col-1)*shape(1)+start(1)-1)*width;
            if fseek(fid,offset,'bof')~=0, error('storage:IO','Binary seek failed.'); end
            [v,n]=fread(fid,count(1),['*' type]);
            if n~=count(1), error('storage:Corrupt','Truncated binary payload.'); end
            x((col-1)*count(1)+(1:count(1)))=v;
        end
    case 'mat'
        if isempty(range)
            m=load(p.data,'x'); x=m.x;
        else
            subs=repmat({':'},1,numel(shape)); subs{1}=range(1):range(2);
            numeric=any(strcmp(info.class,{'double','single','logical','int8','uint8','int16','uint16','int32','uint32','int64','uint64'}));
            if strcmp(info.mat_version,'-v7.3') && numeric
                m=matfile(p.data); x=m.x(subs{:});
            else
                m=load(p.data,'x'); x=m.x(subs{:});
            end
        end
end
end

function publish(st,key,p,stage,info,deleting)
% Same-filesystem staging and rollback on caught errors. Not a cross-resource
% crash transaction: interrupted processes require inspection of temp bundles.
parent=fileparts(p.artifact);
if ~isfolder(parent)
    if ~st.create_parents, error('storage:MissingParent','Parent directory does not exist.'); end
    [ok,msg]=mkdir(parent); if ~ok, error('storage:IO','%s',msg); end
end
backup=''; installed=false; db=[]; transaction=false;
try
    if indexed(st)
        db=open_db(st); guard=onCleanup(@()close(db)); %#ok<NASGU>
        exec(db,'BEGIN IMMEDIATE'); transaction=true;
        exec(db,['DELETE FROM artifacts WHERE key=' quote(key)]);
        if ~deleting
            sql=['INSERT INTO artifacts (key,backend,class,shape,bytes,metadata) VALUES (' ...
                quote(key) ',' quote(info.backend) ',' quote(info.class) ',' ...
                quote(jsonencode(info.size)) ',' sprintf('%.0f',info.bytes) ',' ...
                quote(jsonencode(info.metadata)) ')'];
            exec(db,sql);
        end
    end
    if isfolder(p.artifact)
        backup=tempname(st.root); checked_move(p.artifact,backup);
    end
    if ~deleting, checked_move(stage,p.artifact); installed=true; end
    if transaction, exec(db,'COMMIT'); transaction=false; end
catch err
    if transaction
        try, exec(db,'ROLLBACK'); catch, end
    end
    if installed, remove_dir(p.artifact); end
    if ~isempty(backup) && isfolder(backup), checked_move(backup,p.artifact); end
    rethrow(err);
end
if ~isempty(backup), remove_dir(backup); end
end

function checked_move(a,b)
[ok,msg]=movefile(a,b);
if ~ok, error('storage:IO','%s',msg); end
end
function remove_dir(p)
if isfolder(p), rmdir(p,'s'); end
end
function remove_file(p)
if isfile(p), delete(p); end
end

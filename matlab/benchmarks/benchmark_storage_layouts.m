function results = benchmark_storage_layouts(root, varargin)
%BENCHMARK_STORAGE_LAYOUTS Measure standalone binary vs HDF5, MATLAB R2019a.
% results = benchmark_storage_layouts('/local/nvme/scratch', ...
%   'n_files',[100 1000], 'payload_bytes',[4096 1048576], ...
%   'max_total_bytes',2*2^30,'keep_files',false)
%
% Benchmarks are synthetic, disposable, and independent of storage_* API.
% Every case measures create, write, publish, reopen/read, and cleanup.
% For large sweeps, max_total_bytes caps each case to avoid filling disk.
% No parallel writes to a common HDF5 file. No reliance on NaN as completion.
%
% WARNING: benchmark creates/removes files ONLY in an exclusive directory
% under ROOT. Never point ROOT at your scientific data directly.
if nargin < 1 || isempty(root), root = tempdir; end
assert(isfolder(root), 'benchmark_storage:Root', 'Root must exist.');
p = inputParser;
p.addParameter('n_files',[100 1000 10000],@(x)isnumeric(x)&&isvector(x)&&all(x>0)&all(x==fix(x)));
p.addParameter('payload_bytes',[4096 1048576],@(x)isnumeric(x)&&isvector(x)&&all(x>=4)&all(x==fix(x)));
p.addParameter('max_total_bytes',512*2^20,@(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('keep_files',false,@(x)islogical(x)&&isscalar(x));
p.addParameter('read_fraction',0.1,@(x)isnumeric(x)&&isscalar(x)&&x>0&&x<=1);
p.parse(varargin{:}); o=p.Results;
formats={'binary','binary_preallocated','hdf5_separate','hdf5_grouped'};
results=struct('format',{},'n_files',{},'payload_bytes',{},'create_s',{}, ...
    'write_s',{},'publish_s',{},'read_s',{},'cleanup_s',{}, ...
    'total_s',{},'logical_bytes',{},'read_bytes',{},'read_mib_s',{});
run_dir=tempname(root);
[ok,msg]=mkdir(run_dir); assert(ok,msg);
if ~o.keep_files, guard=onCleanup(@()safe_remove(run_dir)); end
case_id=0;
for ni=1:numel(o.n_files)
    for pi=1:numel(o.payload_bytes)
        requested=o.n_files(ni); bytes=o.payload_bytes(pi);
        if mod(bytes,4)~=0
            warning('benchmark_storage:Alignment','Skipping non-single-aligned payload %g.',bytes);continue;
        end
        n=min(requested,floor(o.max_total_bytes/bytes));
        if n<1,continue;end
        if n<requested
            fprintf('Capped case %d x %d bytes to %d tasks (space budget).\n',requested,bytes,n);
        end
        x=single(1:bytes/4); x(:)=single(NaN); x(1)=single(pi); % deterministic marker
        for ki=1:numel(formats)
            fmt=formats{ki}; case_id=case_id+1;
            dir_case=fullfile(run_dir,sprintf('case_%04d',case_id));
            mkdir(dir_case);
            t_all=tic; t=tic;
            switch fmt
                case {'binary','binary_preallocated'}
                    % Unique independent artifact paths, with .part temporary.
                    for j=1:n
                        fn=fullfile(dir_case,sprintf('%07d.part',j));
                        fid=fopen(fn,'w');assert(fid>=0,'Cannot create %s',fn);fclose(fid);
                    end
                case 'hdf5_separate'
                    for j=1:n
                        fn=fullfile(dir_case,sprintf('%07d.part.h5',j));
                        h5create(fn,'/data',[bytes/4 1], 'Datatype','single', ...
                          'ChunkSize',[min(bytes/4,262144) 1]);
                    end
                case 'hdf5_grouped'
                    fn=fullfile(dir_case,'group.part.h5');
                    h5create(fn,'/data',[bytes/4 n],'Datatype','single', ...
                          'ChunkSize',[min(bytes/4,262144) 1]);
            end
            create_s=toc(t);
            if strcmp(fmt,'binary_preallocated')
                % Sparse sizing with fseek+last byte; NOT guaranteed allocation.
                % Prefer OS fallocate when guaranteed reservation is needed.
                t=tic;
                for j=1:n
                    fn=fullfile(dir_case,sprintf('%07d.part',j));
                    fid=fopen(fn,'r+');assert(fid>=0);
                    assert(fseek(fid,bytes-1,'bof')==0);
                    fwrite(fid,uint8(0),'uint8');fclose(fid);
                end
                create_s=create_s+toc(t);
            end
            t=tic;
            switch fmt
                case {'binary','binary_preallocated'}
                    for j=1:n
                        fn=fullfile(dir_case,sprintf('%07d.part',j));
                        fid=fopen(fn,'r+');assert(fid>=0);
                        count=fwrite(fid,x,'single');fclose(fid);
                        assert(count==numel(x));
                    end
                case 'hdf5_separate'
                    for j=1:n
                        h5write(fullfile(dir_case,sprintf('%07d.part.h5',j)),'/data',x(:));
                    end
                case 'hdf5_grouped'
                    for j=1:n
                        h5write(fullfile(dir_case,'group.part.h5'),'/data',x(:),[1 j],[numel(x) 1]);
                    end
            end
            write_s=toc(t);
            t=tic;
            if strcmp(fmt,'hdf5_grouped')
                movefile(fullfile(dir_case,'group.part.h5'),fullfile(dir_case,'group.ready.h5'));
                fid=fopen(fullfile(dir_case,'group.ready'),'w');fclose(fid);
            else
                for j=1:n
                    if strcmp(fmt,'hdf5_separate')
                        from=sprintf('%07d.part.h5',j);to=sprintf('%07d.ready.h5',j);
                    else
                        from=sprintf('%07d.part',j);to=sprintf('%07d.ready.bin',j);
                    end
                    movefile(fullfile(dir_case,from),fullfile(dir_case,to));
                end
            end
            publish_s=toc(t);
            sample_count=max(1,ceil(n*o.read_fraction));
            sampled=unique(round(linspace(1,n,sample_count)));
            t=tic;
            for idx=1:numel(sampled)
                j=sampled(idx);
                switch fmt
                    case {'binary','binary_preallocated'}
                        fid=fopen(fullfile(dir_case,sprintf('%07d.ready.bin',j)),'r');assert(fid>=0);
                        y=fread(fid,[numel(x) 1],'single=>single');fclose(fid);
                    case 'hdf5_separate'
                        y=h5read(fullfile(dir_case,sprintf('%07d.ready.h5',j)),'/data');
                    case 'hdf5_grouped'
                        y=h5read(fullfile(dir_case,'group.ready.h5'),'/data',[1 j],[numel(x) 1]);
                end
                assert(isequaln(y(:),x(:)),'Readback mismatch.');
            end
            read_s=toc(t); read_bytes=numel(sampled)*bytes;
            t=tic;
            if ~o.keep_files, rmdir(dir_case,'s');end
            cleanup_s=toc(t);
            results(end+1)=struct('format',fmt,'n_files',n,'payload_bytes',bytes, ...
                'create_s',create_s,'write_s',write_s,'publish_s',publish_s, ...
                'read_s',read_s,'cleanup_s',cleanup_s,'total_s',toc(t_all), ...
                'logical_bytes',n*bytes,'read_bytes',read_bytes, ...
                'read_mib_s',(read_bytes/2^20)/max(read_s,eps)); %#ok<AGROW>
            fprintf('%-20s count=%6d payload=%8d B create=%.3fs write=%.3fs publish=%.3fs read=%.3fs\n', ...
                fmt,n,bytes,create_s,write_s,publish_s,read_s);
        end
    end
end
if ~isempty(results)
    T=struct2table(results);
    writetable(T,fullfile(root,['storage_benchmark_' datestr(now,'yyyymmdd_HHMMSS') '.csv']));
end
end
function safe_remove(path)
if isfolder(path),rmdir(path,'s');end
end

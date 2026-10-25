function st = storage_validate(st)
%STORAGE_VALIDATE Validate a descriptor without creating files/connections.
% ST=storage_validate(ST) returns normalized text options.
if ~isstruct(st) || ~isscalar(st), error('storage:Config','Expected scalar struct.'); end
fields=fieldnames(storage_defaults());
if ~isequal(sort(fieldnames(st)),sort(fields))
    error('storage:Config','Descriptor fields must match storage_defaults.');
end
texts={'backend','root','precision','byte_order','mat_version','array_backend'};
for k=1:numel(texts)
    name=texts{k}; v=st.(name);
    if isstring(v) && isscalar(v), v=char(v); end
    if ~ischar(v) || ~isrow(v) || isempty(v) || any(v==0)
        error('storage:Config','%s must be nonempty scalar text.',name);
    end
    st.(name)=v;
end
st.backend=validatestring(st.backend,{'hdf5','binary','mat','sqlite','hybrid'});
st.precision=validatestring(st.precision,{'preserve','single','double'});
st.byte_order=validatestring(st.byte_order,{'ieee-le','ieee-be'});
st.mat_version=validatestring(st.mat_version,{'-v7','-v7.3'});
st.array_backend=validatestring(st.array_backend,{'hdf5','binary'});
flags={'readonly','overwrite','create_parents','mat_compression'};
for k=1:numel(flags)
    if ~islogical(st.(flags{k})) || ~isscalar(st.(flags{k}))
        error('storage:Config','%s must be scalar logical.',flags{k});
    end
end
validateattributes(st.chunk_samples,{'numeric'},{'scalar','real','finite','integer','positive'});
validateattributes(st.compression,{'numeric'},{'scalar','real','finite','integer','>=',0,'<=',9});
validateattributes(st.busy_timeout_ms,{'numeric'},{'scalar','real','finite','integer','nonnegative'});
if strcmp(st.mat_version,'-v7') && ~st.mat_compression
    error('storage:Config','R2019a requires mat_compression=true for -v7.');
end
end

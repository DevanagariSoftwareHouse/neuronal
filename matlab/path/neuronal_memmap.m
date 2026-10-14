function mapping = neuronal_memmap(descriptor, root)
%NEURONAL_MEMMAP Create a read-only memory map from a catalog file entry.
%   M.Data.x has exactly the declared descriptor.shape (column-major).
%   Create a separate mapping inside each parfor worker; do not serialize M.
    if nargin < 2, root = []; end
    info = neuronal_validate_file(descriptor,root);
    mapping = memmapfile(info.path,'Writable',false, ...
        'Offset',info.offset_bytes, ...
        'Format',{info.dtype,info.shape,'x'});
end

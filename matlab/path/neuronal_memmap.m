function mapping = neuronal_memmap(descriptor, root)
%NEURONAL_MEMMAP Create a read-only memory map from a catalog file entry.
%   M.Data.x has exactly the declared descriptor.shape (column-major).
%   Create a separate mapping inside each parfor worker; do not serialize M.
%
%   SYNTAX
%     mapping = neuronal_memmap(descriptor, root)
%
%   INPUTS
%     descriptor: Binary descriptor with path, dtype, shape, endian and optional offset_bytes
%       (default 0).
%     root: Root for relative descriptor paths; default repository root.
%
%   OUTPUTS
%     mapping: Read-only memmapfile object; mapping.Data.x has descriptor.shape and dtype.
%       Native-endian data and exact file size are required.
%
%   The writer example requires a little-endian host for memory mapping.
%
%   EXAMPLE
%     filename = [tempname '.bin'];
%     descriptor = neuronal_write_binary(single(reshape(1:200,100,2)),filename);
%     mapping = neuronal_memmap(descriptor);
%     window = mapping.Data.x(1:10,1);
%     % Clear the mapping before deleting the example file.
%     clear mapping; delete(filename);
%
    if nargin < 2, root = []; end
    info = neuronal_validate_file(descriptor,root);
    mapping = memmapfile(info.path,'Writable',false, ...
        'Offset',info.offset_bytes, ...
        'Format',{info.dtype,info.shape,'x'});
end

function info = neuronal_validate_file(descriptor, root)
%NEURONAL_VALIDATE_FILE Check raw binary schema, byte length, and host endian.
%   This validates storage, not equivalence to the original experiment.
%
%   SIGNATURE DESCRIPTION
%     descriptor — catalog file descriptor or dataset record.
%     root — project/data root directory.
%   RETURNS
%     info — metadata and diagnostics structure.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     info = neuronal_validate_file(descriptor, root);
%
    if nargin < 2, root = []; end
    filename = neuronal_file_path(descriptor,root);
    assert(isfile(filename),'neuronal:storage:Missing','Missing %s',filename);
    for field = {'dtype','shape','endian'}
        assert(isfield(descriptor,field{1}), ...
            'neuronal:storage:Schema','Missing field %s',field{1});
    end
    supported = {'double','single','int8','uint8','int16','uint16', ...
                 'int32','uint32','int64','uint64'};
    bytes = [8,4,1,1,2,2,4,4,8,8];
    dtype = char(descriptor.dtype);
    ix = find(strcmp(dtype,supported),1);
    assert(~isempty(ix),'neuronal:storage:Type','Unsupported dtype: %s',dtype);
    shape = double(descriptor.shape);
    assert(isvector(shape) && ~isempty(shape) && all(isfinite(shape)) && ...
        all(shape >= 1) && all(shape == fix(shape)), ...
        'neuronal:storage:Shape','Shape must contain positive integers.');
    endian = char(descriptor.endian);
    [~, ~, host] = computer; % Third output: 'L' or 'B' (no 'endian' argument).
    assert((strcmp(endian,'ieee-le') && host=='L') || ...
           (strcmp(endian,'ieee-be') && host=='B'), ...
        'neuronal:storage:Endianness', ...
        'memmapfile requires native-endian data; file is %s.',endian);
    offset = 0;
    if isfield(descriptor,'offset_bytes')
        offset = double(descriptor.offset_bytes);
    end
    assert(isscalar(offset) && isfinite(offset) && offset>=0 && ...
        offset==fix(offset),'neuronal:storage:Offset','Invalid byte offset.');
    expected = offset + prod(shape)*bytes(ix);
    actual = dir(filename);
    assert(actual.bytes==expected,'neuronal:storage:Size', ...
        'Size mismatch: %s (expected %.0f, got %.0f bytes).', ...
        filename,expected,actual.bytes);
    info = struct('path',filename,'bytes',actual.bytes, ...
        'dtype',dtype,'shape',shape,'offset_bytes',offset);
end

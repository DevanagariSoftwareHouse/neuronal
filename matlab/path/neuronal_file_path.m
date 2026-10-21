function filename = neuronal_file_path(descriptor, root)
%NEURONAL_FILE_PATH Resolve a catalog file descriptor against a project root.
%   Relative catalog paths are anchored to ROOT (default: neuronal repo).
%
%   SYNTAX
%     filename = neuronal_file_path(descriptor, root)
%
%   INPUTS
%     descriptor: Struct with nonempty path field (relative or absolute).
%     root: Root directory for relative paths; default repository root.
%
%   OUTPUTS
%     filename: Character path; absolute descriptor paths pass through unchanged. No existence
%       check is performed.
%
%   EXAMPLE
%     descriptor = struct('path',fullfile('data','toy.bin'));
%     filename = neuronal_file_path(descriptor,tempdir);
%     % Resolves the path only; no file is created.
%
    assert(isstruct(descriptor) && isfield(descriptor,'path'), ...
        'neuronal:path:Invalid', 'Expected a descriptor with a path.');
    if nargin < 2 || isempty(root)
        root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    end
    filename = char(descriptor.path);
    assert(~isempty(filename), 'neuronal:path:Empty','Empty file path.');
    isAbsolute = startsWith(filename,filesep) || ...
        ~isempty(regexp(filename,'^[A-Za-z]:[\\/]','once')) || ...
        startsWith(filename,'\\');
    if ~isAbsolute
        filename = fullfile(char(root),filename);
    end
end

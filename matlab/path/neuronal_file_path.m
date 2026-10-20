function filename = neuronal_file_path(descriptor, root)
%NEURONAL_FILE_PATH Resolve a catalog file descriptor against a project root.
%   Relative catalog paths are anchored to ROOT (default: neuronal repo).
%
%   SIGNATURE DESCRIPTION
%     descriptor — catalog file descriptor or dataset record.
%     root — project/data root directory.
%   RETURNS
%     filename — the returned filename; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     filename = neuronal_file_path(descriptor, root);
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

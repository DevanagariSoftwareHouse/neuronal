function x = neuronal_read(mapping, samples, channels)
%NEURONAL_READ Read a time x channels window without mapping whole file into RAM.
%   X = NEURONAL_READ(M,SAMPLES,CHANNELS) assumes stored shape [time channels].
%   Samples/channels are MATLAB 1-based indices. Omit channels for all.
%
%   SYNTAX
%     x = neuronal_read(mapping, samples, channels)
%
%   INPUTS
%     mapping: memmapfile object with 2-D Data.x stored as samples-by-channels.
%     samples: Valid 1-based numeric row indices; omitted or [] selects all.
%     channels: Valid 1-based numeric column indices; omitted or [] selects all.
%
%   OUTPUTS
%     x: Selected samples-by-channels matrix in the stored numeric class.
%
%   The writer example requires a little-endian host for memory mapping.
%
%   EXAMPLE
%     filename = [tempname '.bin'];
%     descriptor = neuronal_write_binary(single(reshape(1:200,100,2)),filename);
%     mapping = neuronal_memmap(descriptor);
%     x = neuronal_read(mapping,11:20,2);
%     % x is 10-by-1 single precision.
%     clear mapping; delete(filename);
%
    assert(isa(mapping,'memmapfile'), 'neuronal:read:Map', ...
        'First argument must be a memmapfile object.');
    a = mapping.Data.x;
    assert(ismatrix(a),'neuronal:read:Shape','Expected a 2-D matrix.');
    if nargin < 2 || isempty(samples), samples = 1:size(a,1); end
    if nargin < 3 || isempty(channels), channels = 1:size(a,2); end
    assert(isnumeric(samples) && all(samples(:)>=1) && ...
        all(samples(:)<=size(a,1)) && all(mod(samples(:),1)==0), ...
        'neuronal:read:Samples','Sample indices out of range.');
    assert(isnumeric(channels) && all(channels(:)>=1) && ...
        all(channels(:)<=size(a,2)) && all(mod(channels(:),1)==0), ...
        'neuronal:read:Channels','Channel indices out of range.');
    x = a(samples,channels);
end

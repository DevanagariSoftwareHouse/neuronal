function x = neuronal_read(mapping, samples, channels)
%NEURONAL_READ Read a time x channels window without mapping whole file into RAM.
%   X = NEURONAL_READ(M,SAMPLES,CHANNELS) assumes stored shape [time channels].
%   Samples/channels are MATLAB 1-based indices. Omit channels for all.
%
%   SIGNATURE DESCRIPTION
%     mapping — the mapping value; expected shape, units, and constraints are stated in the notes above.
%     samples — the samples value; expected shape, units, and constraints are stated in the notes above.
%     channels — the channels value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     x — the returned x; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     x = neuronal_read(mapping, samples, channels);
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

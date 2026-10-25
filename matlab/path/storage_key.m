function key = storage_key(varargin)
%STORAGE_KEY Validate a key or build one from named coordinates.
% K=storage_key('session_18/lfp_1/ch_0003/frequency_0007').
% K=storage_key('session','18','area','lfp_1','channel',3,'frequency',7).
% Optional filter and time coordinates follow frequency. Prefer range reads
% over materializing a separate artifact for every temporal window.
if nargin==1
    key=varargin{1}; if isstring(key) && isscalar(key), key=char(key); end
else
    p=inputParser; p.PartialMatching=false;
    names={'session','area','channel','frequency','filter','time'};
    for k=1:numel(names), addParameter(p,names{k},[]); end
    parse(p,varargin{:}); parts={};
    for k=1:numel(names)
        v=p.Results.(names{k}); if isempty(v), continue; end
        name=names{k};
        if any(strcmp(name,{'channel','frequency','time'}))
            validateattributes(v,{'numeric'},{'scalar','real','finite','integer','positive'});
            prefix=name; if strcmp(name,'channel'), prefix='ch'; end
            part=sprintf('%s_%04d',prefix,v);
        else
            if isnumeric(v)
                validateattributes(v,{'numeric'},{'scalar','real','finite','integer','nonnegative'});
                v=sprintf('%.0f',v);
            end
            v=char(v);
            if isempty(regexp(v,'^[A-Za-z0-9][A-Za-z0-9_.-]*$','once'))
                error('storage:Key','Invalid coordinate.');
            end
            if strcmp(name,'area'), part=v; else, part=[name '_' v]; end
        end
        parts{end+1}=part; %#ok<AGROW>
    end
    key=strjoin(parts,'/');
end
if ~ischar(key) || ~isrow(key) || isempty(regexp(key, ...
        '^[A-Za-z0-9][A-Za-z0-9_.-]*(/[A-Za-z0-9][A-Za-z0-9_.-]*)*$','once'))
    error('storage:Key','Use relative slash-separated alphanumeric key components.');
end
parts=strsplit(key,'/');
if any(cellfun(@(v)numel(v)>=6 && strcmp(v(end-5:end),'.store'),parts))
    error('storage:Key','The .store component suffix is reserved.');
end
end

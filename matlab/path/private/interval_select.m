function result = interval_select(nodes, k)
%INTERVAL_SELECT Shared count, indexed-record and explicit bulk output.
if isempty(k)
    result = numel(nodes);
elseif ischar(k) && isequal(k,'all')
    result = nodes;
else
    validateattributes(k, {'numeric'}, {'scalar','real','finite','integer','positive'});
    assert(k <= numel(nodes), 'interval:Index', 'Window index exceeds available intervals.');
    result = nodes(k);
end
end

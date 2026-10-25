function keys = storage_list(st,varargin)
%STORAGE_LIST List committed keys in sorted order.
% KEYS=storage_list(ST); KEYS=storage_list(ST,'session_18').
% Prefix matches a complete key or its descendants, not a SQL wildcard.
keys=storage_internal('list',st,varargin{:});
end

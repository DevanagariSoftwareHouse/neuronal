function st = storage_append(st,key,x)
%STORAGE_APPEND Append rows by validated read/concatenate/rewrite.
% ST=storage_append(ST,KEY,X). Requires matching class and trailing shape.
% This is NOT streaming: needs old+new arrays in RAM and a full rewrite.
% Explicit append is permitted with overwrite=false; other metadata persists.
storage_internal('append',st,key,x);
end

function tf = storage_exists(st,key)
%STORAGE_EXISTS Test whether a committed artifact exists.
% TF=storage_exists(ST,KEY). Catalog-backed stores also check registration.
tf=storage_internal('exists',st,key);
end

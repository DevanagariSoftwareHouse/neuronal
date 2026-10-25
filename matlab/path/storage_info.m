function info = storage_info(st,key)
%STORAGE_INFO Read class, shape, bytes, layout and user metadata.
% INFO=storage_info(ST,KEY) does not load the numerical payload.
info=storage_internal('info',st,key);
end

function st = storage_delete(st,key)
%STORAGE_DELETE Delete an artifact and its catalog entry.
% ST=storage_delete(ST,KEY). Missing keys are an error; readonly is enforced.
storage_internal('delete',st,key);
end

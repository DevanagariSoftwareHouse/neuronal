function st = storage_close(st)
%STORAGE_CLOSE Idempotent close; operations already close their handles.
% ST=storage_close(ST). Descriptor remains reusable; no persistent handles.
storage_validate(st);
end

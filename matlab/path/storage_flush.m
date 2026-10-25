function st = storage_flush(st)
%STORAGE_FLUSH Finish synchronous operations (no user-space buffers).
% ST=storage_flush(ST). Does not promise fsync or power-loss durability.
storage_validate(st);
end

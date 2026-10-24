function filter_require(name)
% Fail explicitly rather than substituting another scientific method.
if exist(name,'file') == 0 && exist(name,'builtin') == 0
    error('neuronal:filter:Dependency', ...
        'Required backend %s is missing. See matlab/FILTERS.md.', name);
end
end

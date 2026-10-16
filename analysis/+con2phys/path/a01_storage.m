%% Binary round trip using a real LFP excerpt, in a NEW temporary directory.
% Demonstrates storage without modifying the source catalog or source binaries.
r=struct('mode','real excerpt / isolated storage');
r.source=neuronal_file_path(d.file(1),repo);
r.validation=neuronal_validate_file(d.file(1),repo);
r.directory=tempname; mkdir(r.directory);
excerpt=single(c.lfp{1}(1:100,:));
descriptor=neuronal_write_binary(excerpt,fullfile(r.directory,'excerpt.bin'));
entry=struct('id','battle_excerpt','file',descriptor);
neuronal_register(fullfile(r.directory,'catalog.mat'),'battle',r.directory,entry);
roundtrip=neuronal_catalog(fullfile(r.directory,'catalog.mat'));
m=neuronal_memmap(roundtrip.data.file);
restored=neuronal_read(m,1:100,1:size(excerpt,2));
assert(isequal(excerpt,restored),'Binary round trip changed data.');
r.exact=true; clear m
% Directory retained for inspection; reported in r.directory.

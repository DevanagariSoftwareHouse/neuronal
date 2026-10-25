function location = storage_path(st,key)
%STORAGE_PATH Resolve a logical key without creating anything.
% L has artifact (bundle directory), metadata, data, dataset and catalog.
% Use STORAGE_READ rather than relying on these implementation paths.
st=storage_validate(st); key=storage_key(key);
b=st.backend;
if strcmp(b,'sqlite'), b='mat'; elseif strcmp(b,'hybrid'), b=st.array_backend; end
ext=struct('hdf5','.h5','binary','.bin','mat','.mat');
location.artifact=fullfile(st.root,'artifacts',[key '.store']);
location.metadata=fullfile(location.artifact,'metadata.mat');
location.data=fullfile(location.artifact,['data' ext.(b)]);
location.dataset='/data'; location.catalog=fullfile(st.root,'catalog.sqlite');
location.backend=b;
end

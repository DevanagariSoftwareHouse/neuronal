%% Synthetic end-to-end test: neuronal BIN / memmap and CON2PHYS digest.
root = tempname; mkdir(root);
cleanup = onCleanup(@() cleanup_dir(root));
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'path'));
source = fullfile(root,'source');
raw = fullfile(root,'raw');
animal = fullfile(source,'01');
mkdir(animal);

lfp1 = reshape(double(1:60),3,20);
lfp2 = reshape(double(101:140),2,20);
lfp3 = reshape(double(201:220),1,20);
save(fullfile(animal,'lfp_1.mat'),'lfp1');
save(fullfile(animal,'lfp_2.mat'),'lfp2');
save(fullfile(animal,'lfp_3.mat'),'lfp3');
spikes = [0.15,0.35,0.75];
clusters = int32([7,3,7]);
wf = single(reshape(1:8,2,4));
brain_areas = struct('description','synthetic; no contact coordinates');
save(fullfile(animal,'spikes.mat'),'spikes');
save(fullfile(animal,'clusters.mat'),'clusters');
save(fullfile(animal,'waveforms.mat'),'wf');
save(fullfile(animal,'brain_area.mat'),'brain_areas');
trials = table([1;2],[3;4],'VariableNames',{'start','stop'});
writetable(trials,fullfile(animal,'trial_data.xlsx'));

entries = con2phys.digest(source,raw,'Animals',1,'RecordStart',1);
assert(numel(entries)==1 && strcmp(entries(1).id,'00001'));
assert(numel(entries(1).file)==6);
assert(numel(entries(1).behavior.trials)==2);
assert(entries(1).n_spikes==3);
assert(all(isnan(entries(1).file(1).position.value)));
assert(isequal(entries(1).file(1).position.depth_order,(1:3)'));

maps = cell(1,3);
original = {lfp1,lfp2,lfp3};
for r = 1:3
    desc = entries(1).file(r);
    info = neuronal_validate_file(desc);
    assert(info.bytes==numel(original{r})*8);
    maps{r} = neuronal_memmap(desc);
    assert(isequal(maps{r}.Data.x,original{r}.'));
    assert(isequal(neuronal_read(maps{r},3:8,1), ...
        original{r}(1,3:8).'));
end
clear maps

timesMap = neuronal_memmap(entries(1).file(4));
clustersMap = neuronal_memmap(entries(1).file(5));
wfMap = neuronal_memmap(entries(1).file(6));
assert(isequal(timesMap.Data.x,spikes(:)));
assert(isequal(clustersMap.Data.x,clusters(:)));
assert(isequal(wfMap.Data.x,wf.'));
clear timesMap clustersMap wfMap

catalogPath = fullfile(root,'neuronal','catalog.mat');
catalog = neuronal_register(catalogPath,'con2phys', ...
    'matlab/path/+con2phys/digest.m',entries);
assert(numel(catalog)==1);
loaded = neuronal_catalog(catalogPath);
assert(strcmp(loaded(1).digest_alias,'con2phys'));
assert(strcmp(loaded(1).data(1).file(1).dtype,'double'));
raised = false;
try
    neuronal_register(catalogPath,'con2phys','digest.m',entries);
catch ME
    raised = strcmp(ME.identifier,'neuronal:register:Exists');
end
assert(raised);
loaded = neuronal_register(catalogPath,'con2phys', ...
    'matlab/path/+con2phys/digest.m',entries,'Replace',true);
assert(numel(loaded)==1);

% A corrupted raw file must not map.
filename = entries(1).file(1).path;
fid = fopen(filename,'a'); assert(fid>0);
fwrite(fid,uint8(1),'uint8'); fclose(fid);
raised = false;
try
    neuronal_memmap(entries(1).file(1));
catch ME
    raised = strcmp(ME.identifier,'neuronal:storage:Size');
end
assert(raised);
clear cleanup
fprintf('Neuronal raw storage synthetic checks passed.\n');

function cleanup_dir(path)
    if isfolder(path), rmdir(path,'s'); end
end

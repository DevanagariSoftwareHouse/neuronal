%% CON2PHYS arsenal: bounded real-data context. SCRIPT; keeps cfg overrides.
battle_path=fileparts(mfilename('fullpath'));
repo=fileparts(fileparts(fileparts(battle_path)));
addpath(fullfile(repo,'matlab','path')); addpath(battle_path);
if ~exist('cfg','var'), cfg=struct(); end
defaults=struct('session',1,'seconds',60,'start_s',0,'seed',42,'draws',199, ...
    'max_clusters',12,'plots',true,'label_field','','catalog', ...
    fullfile(repo,'data','neuronal','catalog.mat'));
fn=fieldnames(defaults);
for j=1:numel(fn)
    if ~isfield(cfg,fn{j}), cfg.(fn{j})=defaults.(fn{j}); end
end
assert(cfg.seconds>=20 && cfg.start_s>=0 && cfg.draws>=20);
rng(cfg.seed,'twister');
catalog=neuronal_catalog(cfg.catalog);
which_dataset=find(strcmpi({catalog.digest_alias},'con2phys'));
assert(numel(which_dataset)==1,'Select a catalog with exactly one con2phys entry.');
records=catalog(which_dataset).data;
d=records(cfg.session); c=struct();
c.session=d.id; c.fs=double(d.file(1).sampling_rate_hz);
c.duration=double(d.n_lfp_samples)/c.fs;
c.first=floor(cfg.start_s*c.fs)+1;
c.last=min(double(d.n_lfp_samples),c.first+floor(cfg.seconds*c.fs)-1);
c.origin=(c.first-1)/c.fs; c.T=(c.last-c.first+1)/c.fs;
assert(c.T>=20 && c.fs>160,'Need >=20 s LFP and fs >160 Hz.');
c.lfp=cell(1,3);
for j=1:3
    m=neuronal_memmap(d.file(j),repo);
    c.lfp{j}=double(neuronal_read(m,c.first:c.last,1:min(4,d.file(j).shape(2))));
end
c.x=c.lfp{1}(:,1); c.y=c.lfp{2}(:,1);
assert(all(isfinite([c.x;c.y])),'Nonfinite LFP: inspect artifacts before analysis.');
m=neuronal_memmap(d.file(4),repo); st=double(m.Data.x(:));
m=neuronal_memmap(d.file(5),repo); sc=double(m.Data.x(:));
assert(numel(st)==numel(sc) && all(isfinite(st)) && all(isfinite(sc)));
c.ids=double(d.brain_areas.cluster_id(:));
c.area=double(d.brain_areas.brain_area(:));
assert(numel(unique(c.ids))==numel(c.ids) && numel(c.area)==numel(c.ids));
c.spikes=cell(numel(c.ids),1); c.local=cell(size(c.spikes));
for j=1:numel(c.ids)
    c.spikes{j}=sort(st(sc==c.ids(j) & st>=0 & st<c.duration));
    c.local{j}=c.spikes{j}(c.spikes{j}>=c.origin & c.spikes{j}<c.origin+c.T)-c.origin;
end
c.edges=0:.1:c.T; c.counts=spike_bins(c.local,c.edges);
c.selected=find(std(c.counts,0,1)>0);
c.selected=c.selected(1:min(cfg.max_clusters,numel(c.selected)));
assert(numel(c.selected)>=3,'Need >=3 active clusters; change session/window.');
c.C=c.counts(:,c.selected); c.s=c.local{c.selected(1)}; c.s2=c.local{c.selected(2)};
tr=d.behavior.trials; c.windows=double([[tr.trial_start]' [tr.trial_end]']);
good=all(isfinite(c.windows),2)&c.windows(:,1)>=0&c.windows(:,2)<=c.duration&diff(c.windows,1,2)>0;
c.trial_index=find(good); c.windows=c.windows(good,:);
c.trial_rates=trial_features(c.spikes,c.windows);
c.events=c.windows(:,1)-c.origin;
c.events=c.events(c.events>=1 & c.events<c.T-1);
clear st sc m
fprintf('CON2PHYS %s: %.1f s LFP; %d mapped clusters; %d valid trials.\n',c.session,c.T,numel(c.ids),size(c.windows,1));

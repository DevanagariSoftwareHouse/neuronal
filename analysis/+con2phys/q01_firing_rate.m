%% Q1: lowest mean single-unit firing rate across the complete recording.

a00_startup

%%
catalog = neuronal_catalog()

%%

files_spike= cellfun(@(f)f(4),{catalog.data.file})
files_cluster= cellfun(@(f)f(5),{catalog.data.file})
%%
for s = 1
    spikes = neuronal_memmap(files_spike(s))
    cluster = neuronal_memmap(files_cluster(s))
end
%%

cluster.Data.x
%%
%%
values=cell(3,1);
for a=1:3, values{a}=qctx.rate(qctx.area==a); end
q01=summarize_questionnaire(values,qctx.labels,'spikes/s/unit', ...
    'All mapped units, including silent units; unit bootstrap within recording.',qcfg);
q01.unit=table(qctx.ids,qctx.area,qctx.rate,'VariableNames',{'cluster','area','rate_hz'});
q01.excluded_spikes=qctx.excluded_spikes;
q01.provenance=qctx.provenance;
disp(q01.summary)

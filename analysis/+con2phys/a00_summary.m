clc
clear
a00_startup
%%
catalog = neuronal_catalog;
%%
clc
fprintf("Schema version: %d\n",catalog.schema_version)
fprintf("Digest alias: %s (%s)\n",catalog.digest_alias,catalog.digest_path)
fprintf("Number of animals: %d\n",size(catalog.data,2))
% %
for d = 1 : size(catalog.data,2)

    data = catalog.data(d);
    fprintf("\tid: %s\n",data.id)%: '00001'
    fprintf("\t\tsource_id: %s\n",data.source_id)%: '01'
    fprintf("\t\tpath: %s\n",data.path)%: 'data/raw/00001'
    fprintf("\t\tsource_path: %s\n",data.source_path)%: 'data/source/con2phys/01'
    file = data.file;

    for f = 1 : size(file,2)
        fprintf("\t\t\tfile: %s\n",file(f).path)%: [1×6 struct]
    end
    %continue
    %fprintf("brain_areas: %s\n",data.brain_areas)%: [1×1 struct]
    %fprintf("behavior: %s\n",data.behavior)%: [1×1 struct]
    fprintf("\t\tn_spikes: %d\n",data.n_spikes)%: 2525186
    fprintf("\t\tn_waveforms: %d\n",data.n_waveforms)%: 88
    fprintf("\t\tn_lfp_samples: %d\n",data.n_lfp_samples)%: 1675486

end

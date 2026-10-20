%% Q1: mean mapped-cluster firing rate over the complete recording.
qid='q01'; con2phys.q00_prepare
values=cell(3,1);
for a=1:3, values{a}=qctx.rate(qctx.area==a); end
q01=summarize_questionnaire(values,qctx.labels,'spikes/s/cluster', ...
    'Full-recording count/exposure; silent mapped clusters retained.',qcfg,'unit');
q01.unit=table(qctx.ids,qctx.area,qctx.rate,'VariableNames',{'cluster','area','rate_hz'});
q01.excluded_spikes=qctx.excluded_spikes; q01.provenance=qctx.provenance;
q01.limitations='Within-recording cluster sampling; clusters are not independent animal replicates or validated single units.';
disp(q01.summary)

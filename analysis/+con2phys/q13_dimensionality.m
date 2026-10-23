%% Q13: participation ratio for a fixed matched cluster subset per area.
qid='q13'; con2phys.q00_prepare
[t,~,valid]=trial_times(data,qcfg); t=t(valid,:); original_trials=find(valid);
% Require >=2 full 100 ms bins in each trial, identically across areas.
keep=arrayfun(@(k)numel(t(k,2):.1:t(k,3))>=3,(1:size(t,1))');
t=t(keep,:); original_trials=original_trials(keep);
stream=RandStream('mt19937ar','Seed',qcfg.seed);
m=min([qcfg.matched_units;arrayfun(@(a)sum(qctx.area==a),(1:3)')]);
assert(m>=2,'Dimensionality requires >=2 clusters per area.');
statistics=cell(3,1); selected=cell(3,1); area_trials=cell(3,1);
for a=1:3
    units=find(qctx.area==a); units=units(randperm(stream,numel(units),m));
    selected{a}=qctx.ids(units); trials=cell(size(t,1),1);
    for k=1:size(t,1)
        trials{k}=spike_bins(qctx.spikes(units),t(k,2):.1:t(k,3));
    end
    area_trials{a}=trials;
    statistics{a}=@(ids)questionnaire_trial_participation(ids,trials);
end
q13=questionnaire_joint_summary((1:size(t,1))',statistics,qctx.labels, ...
    'effective dimensions','Whole-trial resampling; fixed matched cluster subset; PR recomputed per replicate.',qcfg,'trial');
q13.selected_clusters=selected; q13.matched_units=m; q13.retained_trials=original_trials;
q13.trials=area_trials; q13.provenance=qctx.provenance;
q13.limitations='Conditional on the selected cluster subset. Longer trials contribute more bins; raw covariance weights high-variance units. Vary the seed separately for subset sensitivity.';
disp(q13.summary)

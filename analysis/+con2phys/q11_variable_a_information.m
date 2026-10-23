%% Q11: conditional uncertainty of held-out decoded information about A.
qid='q11'; con2phys.q00_prepare
[t,labels,valid]=trial_times(data,qcfg);
valid=valid & isfinite(labels(:,1)); t=t(valid,:); y=labels(valid,1);
original_trials=find(valid);
stream=RandStream('mt19937ar','Seed',qcfg.seed);
m=min([qcfg.matched_units;arrayfun(@(a)sum(qctx.area==a),(1:3)')]);
assert(m>=1,'Each area needs mapped clusters.');
null=nan(3,qcfg.null_replicates);
details=cell(3,1); selected=cell(3,1); predictions=nan(numel(y),3);
for a=1:3
    units=find(qctx.area==a); units=units(randperm(stream,numel(units),m));
    selected{a}=qctx.ids(units);
    x=trial_features(qctx.spikes(units),t(:,[1 4]));
    assert(all(isfinite(x(:))),'All areas must use identical valid trials.');
    [~,d]=decode_trials(x,y,qcfg.seed); details{a}=d;
    predictions(:,a)=d.predicted;
    for b=1:qcfg.null_replicates
        shifted=circshift(y,randi(stream,numel(y)-1));
        [~,dnull]=decode_trials(x,shifted,qcfg.seed);
        null(a,b)=decoded_mi(dnull.observed,dnull.predicted);
    end
end
assert(all(isfinite(predictions(:))), ...
    'questionnaire:Coverage','Incomplete held-out coverage; inspect fold/class support before inference.');
x=[y predictions]; statistics=cell(3,1);
for a=1:3, column=a+1; statistics{a}=@(z)decoded_mi(z(:,1),z(:,column)); end
q11=questionnaire_joint_summary(x,statistics,qctx.labels,'bits', ...
    'MI of held-out predictions; joint trial resampling conditional on fitted models.',qcfg,'trial');
q11.null_bits=null; q11.decoding=details; q11.selected_clusters=selected; q11.retained_trials=original_trials;
q11.limitations='Does not include decoder-training uncertainty or estimate full neural MI. Surrogate null testing is separate from confidence intervals.';
q11.provenance=qctx.provenance;
disp(q11.summary)

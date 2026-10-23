%% Q12: paired segment decoding, conditional on fitted models.
qid='q12'; con2phys.q00_prepare
[t,labels,valid]=trial_times(data,qcfg);
valid=valid & isfinite(labels(:,2)); t=t(valid,:); y=labels(valid,2);
assert(all(ismember(unique(y),[1 2 3])),'Variable C must be categorical 1-3.');
classes=unique(y); assert(numel(classes)==3,'All three C classes are required.');
stream=RandStream('mt19937ar','Seed',qcfg.seed);
null=nan(3,qcfg.null_replicates);
detail=cell(3,1); predictions=nan(numel(y),3);
for segment=1:3
    x=trial_features(qctx.spikes,t(:,segment:segment+1));
    assert(all(isfinite(x(:))),'All segments must use identical valid trials.');
    [~,d]=decode_trials(x,y,qcfg.seed); detail{segment}=d;
    predictions(:,segment)=d.predicted;
    for b=1:qcfg.null_replicates
        shifted=circshift(y,randi(stream,numel(y)-1));
        null(segment,b)=decode_trials(x,shifted,qcfg.seed);
    end
end
assert(all(isfinite(predictions(:))), ...
    'questionnaire:Coverage','Incomplete held-out coverage; inspect fold/class support before inference.');
x=[y predictions]; statistics=cell(3,1);
for segment=1:3
    column=segment+1;
    statistics{segment}=@(z)questionnaire_balanced_accuracy(z,classes,column);
end
q12=questionnaire_joint_summary(x,statistics, ...
    {'Trial start -> Stim';'Stim -> Outcome';'Outcome -> End'},'balanced accuracy', ...
    'Common contiguous folds; joint trial resampling conditional on fitted models.',qcfg,'trial');
q12.null_accuracy=null; q12.decoding=detail; q12.retained_trials=find(valid); q12.provenance=qctx.provenance;
q12.limitations='Undefined replicates with absent classes raise an error; no class is silently discarded. Duration matching and training uncertainty need separate analysis.';
disp(q12.summary)

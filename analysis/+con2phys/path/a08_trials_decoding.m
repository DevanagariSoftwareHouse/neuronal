%% Actual trial labels must be explicitly selected; no invented behavioral meaning.
assert(~isempty(cfg.label_field),'battle:skip','Set cfg.label_field to a verified numeric trial column.');
assert(isfield(tr,cfg.label_field),'battle:skip','Requested label column does not exist.');
y=double([tr(c.trial_index).(cfg.label_field)]'); X=c.trial_rates(:,c.selected);
keep=isfinite(y)&all(isfinite(X),2); X=X(keep,:); y=y(keep);
assert(numel(unique(y))==2 && all(arrayfun(@(v)sum(y==v)>=10,unique(y))), ...
    'battle:skip','This demonstration requires two conditions with >=10 trials each.');
r=struct('mode','real / explicit labels','label_field',cfg.label_field);
r.marginal=condition_marginalization(X,y);
[r.noise,r.residual]=noise_correlation(X,y);
classes=unique(y); r.discrimination=linear_discriminability(X(y==classes(1),:),X(y==classes(2),:),1);
r.interleaved=crossvalidated_ridge_decoder(X,y,5,1);
[r.blocked_accuracy,r.blocked]=decode_trials(X,y,cfg.seed);
r.decoded_information=decoded_mi(r.blocked.observed,r.blocked.predicted);
r.folds=blocked_cross_validation(size(X,1),5,2);
% dDR fitted ONLY on the first fold training data, for visualization.
train=r.folds{1}.train; test=r.folds{1}.test;
r.ddr=targeted_dimensionality_reduction(X(train,:),y(train));
r.ddr_heldout=X(test,:)*r.ddr.basis;

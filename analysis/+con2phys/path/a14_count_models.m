%% Real count series under an explicit IID Poisson model (model check, not fact).
% Parametric CI validity depends on the model; burstiness is a likely mismatch.
r=struct('mode','real counts / Poisson model assumption'); x=c.C(:,1); B=cfg.draws;
assert(exist('poissrnd','file')==2 && exist('gamrnd','file')==2, ...
    'battle:skip','Statistics and Machine Learning Toolbox required.');
[r.parametric_ci,r.mean,r.draws]=parametric_bootstrap_ci(x,@mean, ...
    @(lambda,n)poissrnd(lambda,n,1),@mean,B,.95);
% Gamma(1,rate=1) prior; posterior Gamma(1+sum counts, rate=1+n).
% Each draw samples lambda AND replicated counts, as required by the API.
r.predictive=posterior_predictive_check(x,@(z)[mean(z),var(z)], ...
    @()poissrnd(gamrnd(1+sum(x),1/(1+numel(x))),numel(x),1),B);
r.note='Posterior predictive tail probabilities are not frequentist p-values.';

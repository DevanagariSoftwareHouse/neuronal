function out = posterior_predictive_check(observed,statfun,drawfun,B)
%POSTERIOR_PREDICTIVE_CHECK Simulated replicated data from posterior.
% drawfun() must draw posterior parameters AND posterior predictive data.
% Posterior predictive tail probabilities are NOT uniform frequentist p-values.
if nargin<4||isempty(B), B=999; end
assert(B>=20); obs=reshape(statfun(observed),1,[]);
rep=zeros(B,numel(obs));
for k=1:B
    v=reshape(statfun(drawfun()),1,[]);
    assert(numel(v)==numel(obs)&&all(isfinite(v)));
    rep(k,:)=v;
end
out=struct('observed',obs,'replicated',rep, ...
    'posterior_predictive_tail',mean(bsxfun(@ge,rep,obs),1));
end

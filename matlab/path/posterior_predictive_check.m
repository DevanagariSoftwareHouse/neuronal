function out = posterior_predictive_check(observed,statfun,drawfun,B)
%POSTERIOR_PREDICTIVE_CHECK Simulated replicated data from posterior.
% drawfun() must draw posterior parameters AND posterior predictive data.
% Posterior predictive tail probabilities are NOT uniform frequentist p-values.
%
%   SIGNATURE DESCRIPTION
%     observed — the observed value; expected shape, units, and constraints are stated in the notes above.
%     statfun — function handle that computes the requested statistic.
%     drawfun — the drawfun value; expected shape, units, and constraints are stated in the notes above.
%     B — number of bootstrap/permutation/surrogate draws.
%   RETURNS
%     out — the returned out; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     out = posterior_predictive_check(observed, statfun, drawfun, B);
%
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

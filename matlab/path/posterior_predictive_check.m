function out = posterior_predictive_check(observed,statfun,drawfun,B)
%POSTERIOR_PREDICTIVE_CHECK Simulated replicated data from posterior.
% drawfun() must draw posterior parameters AND posterior predictive data.
% Posterior predictive tail probabilities are NOT uniform frequentist p-values.
%
%   SYNTAX
%     out = posterior_predictive_check(observed,statfun,drawfun,B)
%
%   INPUTS
%     observed: Observed dataset accepted by statfun.
%     statfun: Function returning a fixed-size finite statistic.
%     drawfun: Zero-argument function drawing parameters from a posterior and then replicated
%       observations.
%     B: Integer replicate count >=20; default 999.
%
%   OUTPUTS
%     out: Struct with observed (1-by-P), replicated (B-by-P) and posterior_predictive_tail
%       (fraction of replicated statistics >= observed).
%
%   EXAMPLE
%     rng(7); x = randn(30,1);
%     % Known unit variance and flat prior: posterior mean is N(mean(x),1/n).
%     drawfun = @() mean(x)+randn/sqrt(numel(x))+randn(size(x));
%     out = posterior_predictive_check(x,@mean,drawfun,500);
%     % This posterior predictive tail is not a frequentist calibrated p-value.
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

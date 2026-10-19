function [ci,theta,draws,weights] = bayesian_bootstrap_ci(x,statfun,B,level,seed)
%BAYESIAN_BOOTSTRAP_CI Rubin (1981) Dirichlet-weight bootstrap.
% SIGNATURE: [ci,theta,draws,weights] = bayesian_bootstrap_ci(x,statfun,B,level,seed)
% INPUTS:
%   x       double [n x d] finite data; rows are independent units, n>=2
%   statfun function_handle @(x,w)->double [1 x k] (default weighted mean);
%           w is double [n x 1], positive and sums to 1
%   B       positive integer scalar >=20, draws (default 2000)
%   level   double scalar in (0,1), credible mass (default .95)
%   seed    nonnegative integer scalar, RNG seed (default 42)
% OUTPUTS:
%   ci      double [2 x k], lower/upper posterior quantiles by column
%   theta   double [1 x k], statistic under uniform weights
%   draws   double [B x k], weighted statistic from each Dirichlet draw
%   weights double [n x B], sampled weights (only populated if requested)
% Rows are independent observational units. STATFUN(x,w) must accept
% normalized observation weights and return a finite scalar or row vector.
% This is a Bayesian-bootstrap credible interval, not a frequentist CI.
if nargin<2 || isempty(statfun)
    statfun=@(a,w)sum(a.*w,1);
end
if nargin<3 || isempty(B), B=2000; end
if nargin<4 || isempty(level), level=.95; end
if nargin<5 || isempty(seed), seed=42; end
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1);
assert(n>=2&&B>=20&&level>0&&level<1);
theta=reshape(statfun(x,ones(n,1)/n),1,[]);
assert(all(isfinite(theta)));
stream=RandStream('mt19937ar','Seed',seed);
draws=zeros(B,numel(theta));
if nargout>=4, weights=zeros(n,B); else, weights=[]; end
for b=1:B
    e=-log(max(rand(stream,n,1),realmin));
    w=e/sum(e); % Dirichlet(1,...,1)
    v=reshape(statfun(x,w),1,[]);
    assert(numel(v)==numel(theta)&&all(isfinite(v)), ...
        'Statistic must return a finite, fixed-size estimate.');
    draws(b,:)=v;
    if nargout>=4, weights(:,b)=w; end
end
ci=quantile(draws,[(1-level)/2,(1+level)/2],1);
end

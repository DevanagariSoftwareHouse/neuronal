function [ci,theta,draws] = balanced_bootstrap_ci(x,statfun,B,level,seed)
%BALANCED_BOOTSTRAP_CI Balanced nonparametric bootstrap percentile CI.
% Each independent row appears exactly B times over all B replicates.
% Resamples remain dependent across replicates by design.
if nargin<2||isempty(statfun), statfun=@(a)mean(a,1); end
if nargin<3||isempty(B), B=2000; end
if nargin<4||isempty(level), level=.95; end
if nargin<5||isempty(seed), seed=42; end
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1); assert(n>=2&&B>=20&&level>0&&level<1);
theta=reshape(statfun(x),1,[]);
assert(all(isfinite(theta)));
stream=RandStream('mt19937ar','Seed',seed);
pool=repmat((1:n)',B,1);
idx=reshape(pool(randperm(stream,numel(pool))),n,B);
draws=zeros(B,numel(theta));
for b=1:B
    v=reshape(statfun(x(idx(:,b),:)),1,[]);
    assert(numel(v)==numel(theta)&&all(isfinite(v)));
    draws(b,:)=v;
end
ci=quantile(draws,[(1-level)/2,(1+level)/2],1);
end

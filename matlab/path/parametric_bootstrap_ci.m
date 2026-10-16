function [ci,theta,draws] = parametric_bootstrap_ci(data,fitfun,simulatefun,statfun,B,level)
%PARAMETRIC_BOOTSTRAP_CI Fit model then simulate estimator distribution.
% fitfun(data)->params; simulatefun(params,n)->synthetic data.
% statfun(data)->scalar or vector estimate; percentile CI (draft).
if nargin<5||isempty(B), B=999; end
if nargin<6||isempty(level), level=.95; end
assert(B>=20&&level>0&&level<1);
n=size(data,1); theta=reshape(statfun(data),1,[]);
params=fitfun(data); draws=zeros(B,numel(theta));
for k=1:B
    simulated=simulatefun(params,n);
    v=reshape(statfun(simulated),1,[]);
    assert(numel(v)==numel(theta)&&all(isfinite(v)));
    draws(k,:)=v;
end
ci=quantile(draws,[(1-level)/2,(1+level)/2],1);
end

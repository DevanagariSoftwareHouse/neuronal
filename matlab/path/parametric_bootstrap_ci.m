function [ci,theta,draws] = parametric_bootstrap_ci(data,fitfun,simulatefun,statfun,B,level)
%PARAMETRIC_BOOTSTRAP_CI Fit model then simulate estimator distribution.
% fitfun(data)->params; simulatefun(params,n)->synthetic data.
% statfun(data)->scalar or vector estimate; percentile CI (draft).
%
%   SYNTAX
%     [ci,theta,draws] = parametric_bootstrap_ci(data,fitfun,simulatefun,statfun,B,level)
%
%   INPUTS
%     data: Dataset with observations in rows.
%     fitfun: Function fitfun(data) returning model parameters.
%     simulatefun: Function simulatefun(params,n) generating a dataset with n rows.
%     statfun: Function returning a fixed-size finite statistic.
%     B: Integer replicate count >=20; default 999.
%     level: Confidence probability in (0,1); default 0.95.
%
%   OUTPUTS
%     ci: 2-by-P percentile bounds.
%     theta: 1-by-P statistic on data.
%     draws: B-by-P simulated statistics.
%
%   EXAMPLE
%     rng(7); x = randn(30,1);
%     fitfun = @(z) [mean(z),std(z)];
%     simulatefun = @(p,n) p(1)+p(2)*randn(n,1);
%     [ci, theta, draws] = parametric_bootstrap_ci(x,fitfun,simulatefun,@mean,500,0.95);
%     % The assumed model here is IID Gaussian.
%
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

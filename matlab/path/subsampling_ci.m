function [ci,theta,draws] = subsampling_ci(x,statfun,m,B,level)
%SUBSAMPLING_CI Subsampling CI via scaled estimator differences.
% Validity requires a suitable subsample size m and asymptotic regime.
% For mean-like root-n estimators; independent observations in rows.
%
%   SYNTAX
%     [ci,theta,draws] = subsampling_ci(x,statfun,m,B,level)
%
%   INPUTS
%     x: Finite independent-observations-by-features matrix.
%     statfun: Function returning a fixed-size statistic; default column means.
%     m: Integer subsample size, 2 <= m < n; default max(2,floor(sqrt(n))).
%     B: Integer draws >=20; default 999.
%     level: Confidence probability in (0,1); default 0.95.
%
%   OUTPUTS
%     ci: 2-by-P bounds from root-n scaled subsampling differences.
%     theta: 1-by-P original statistic.
%     draws: B-by-P statistics from sampling rows without replacement.
%
%   EXAMPLE
%     rng(7); x = randn(100,2);
%     [ci, theta, draws] = subsampling_ci(x,[],10,500,0.95);
%     % This scaling targets mean-like root-n estimators.
%
if nargin<2||isempty(statfun), statfun=@(z)mean(z,1); end
n=size(x,1);
if nargin<3||isempty(m), m=max(2,floor(sqrt(n))); end
if nargin<4||isempty(B), B=999; end
if nargin<5||isempty(level), level=.95; end
assert(isnumeric(x)&&all(isfinite(x(:)))&&m>=2&&m<n&&B>=20);
theta=reshape(statfun(x),1,[]); draws=zeros(B,numel(theta));
for k=1:B
    idx=randperm(n,m);
    draws(k,:)=reshape(statfun(x(idx,:)),1,[]);
end
root=sqrt(m)*(draws-theta);
q=quantile(root,[(1-level)/2,(1+level)/2],1);
ci=[theta-q(2,:)/sqrt(n);theta-q(1,:)/sqrt(n)];
end

function [ci,theta,draws] = subsampling_ci(x,statfun,m,B,level)
%SUBSAMPLING_CI Subsampling CI via scaled estimator differences.
% Validity requires a suitable subsample size m and asymptotic regime.
% For mean-like root-n estimators; independent observations in rows.
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

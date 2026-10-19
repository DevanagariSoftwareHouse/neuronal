function [ci,beta,draws] = wild_bootstrap_ci(X,y,B,level,seed,weights)
%WILD_BOOTSTRAP_CI Fixed-design wild residual bootstrap for OLS coefficients.
% X includes any desired intercept column; rows must be independent.
% Rademacher or Mammen multipliers, centered on fitted residuals.
% Percentile intervals are exploratory; heteroskedasticity is allowed.
if nargin<3||isempty(B), B=2000; end
if nargin<4||isempty(level), level=.95; end
if nargin<5||isempty(seed), seed=42; end
if nargin<6||isempty(weights), weights='rademacher'; end
assert(isnumeric(X)&&ismatrix(X)&&isnumeric(y)&&isvector(y));
y=y(:); [n,p]=size(X);
assert(n>p&&numel(y)==n&&rank(X)==p&& ...
    all(isfinite(X(:)))&&all(isfinite(y))&&B>=20&&level>0&&level<1);
beta=X\y;
resid=y-X*beta;
% HC2 residual adjustment reduces leverage-induced underdispersion.
h=sum((X/(X'*X)).*X,2);
assert(all(h<1),'Leverage must be below one.');
resid=resid./sqrt(1-h);
stream=RandStream('mt19937ar','Seed',seed);
draws=zeros(B,p);
for b=1:B
    u=rand(stream,n,1);
    switch lower(char(weights))
        case 'rademacher'
            v=2*(u>=.5)-1;
        case 'mammen'
            a=(1-sqrt(5))/2; c=(1+sqrt(5))/2;
            v=a*ones(n,1); v(u>=(sqrt(5)+1)/(2*sqrt(5)))=c;
        otherwise
            error('Unknown wild bootstrap multiplier.');
    end
    ystar=X*beta+resid.*v;
    draws(b,:)=(X\ystar)';
end
ci=quantile(draws,[(1-level)/2,(1+level)/2],1);
end

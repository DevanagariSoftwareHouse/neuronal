function [ci,theta,tboot] = bootstrap_t_ci(x,statfun,sefun,B,level,seed)
%BOOTSTRAP_T_CI Draft studentized IID bootstrap for scalar statistic.
% statfun and sefun must operate on observations in rows.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%     statfun — function handle that computes the requested statistic.
%     sefun — the sefun value; expected shape, units, and constraints are stated in the notes above.
%     B — number of bootstrap/permutation/surrogate draws.
%     level — confidence level between 0 and 1.
%     seed — random-number generator seed.
%   RETURNS
%     ci — confidence interval (one row per statistic, lower and upper limits in columns).
%     theta — the returned value; see the summary above for meaning and units.
%     tboot — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [ci, theta, tboot] = bootstrap_t_ci(x, statfun, sefun, B, level, seed);
%
if nargin<4||isempty(B), B=2000; end
if nargin<5||isempty(level), level=.95; end
if nargin<6||isempty(seed), seed=42; end
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1); assert(n>=3&&B>=20&&level>0&&level<1);
theta=statfun(x); se=sefun(x);
assert(isscalar(theta)&&isfinite(theta)&&isscalar(se)&&isfinite(se)&&se>0);
stream=RandStream('mt19937ar','Seed',seed); tboot=zeros(B,1);
for k=1:B
    sample=x(randi(stream,n,n,1),:);
    s=sefun(sample);
    assert(isscalar(s)&&isfinite(s)&&s>0);
    tboot(k)=(statfun(sample)-theta)/s;
end
ci=theta-se*fliplr(quantile(tboot,[(1-level)/2,(1+level)/2]));
end

function [ci,theta,tboot] = bootstrap_t_ci(x,statfun,sefun,B,level,seed)
%BOOTSTRAP_T_CI Draft studentized IID bootstrap for scalar statistic.
% statfun and sefun must operate on observations in rows.
%
%   SYNTAX
%     [ci,theta,tboot] = bootstrap_t_ci(x,statfun,sefun,B,level,seed)
%
%   INPUTS
%     x: Finite observations-by-features matrix with at least 3 independent rows.
%     statfun: Function returning a finite scalar statistic.
%     sefun: Function returning a finite positive scalar standard error on every sample.
%     B: Integer replicate count >=20; default 2000.
%     level: Confidence probability in (0,1); default 0.95.
%     seed: Local mt19937ar seed; default 42.
%
%   OUTPUTS
%     ci: 1-by-2 studentized lower/upper bounds.
%     theta: Original scalar statistic.
%     tboot: B-by-1 studentized bootstrap statistics.
%
%   EXAMPLE
%     rng(7); x = randn(40,1);
%     sefun = @(z) std(z)/sqrt(numel(z));
%     [ci, theta, tboot] = bootstrap_t_ci(x,@mean,sefun,500,0.95,7);
%     % sefun must also be positive on each bootstrap sample.
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

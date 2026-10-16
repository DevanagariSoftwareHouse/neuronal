function [ci,theta,boot] = bootstrap_ci(x,statfun,B,level,method,seed)
%BOOTSTRAP_CI Draft IID confidence intervals: percentile, basic, BCa.
% Observations are rows. Do not use IID resampling for correlated bins.
if nargin<2 || isempty(statfun), statfun=@mean; end
if nargin<3 || isempty(B), B=2000; end
if nargin<4 || isempty(level), level=.95; end
if nargin<5 || isempty(method), method='percentile'; end
if nargin<6 || isempty(seed), seed=42; end
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1); assert(n>=3&&B>=20&&level>0&&level<1);
theta=statfun(x); assert(isscalar(theta)&&isfinite(theta));
stream=RandStream('mt19937ar','Seed',seed);
boot=zeros(B,1);
for k=1:B
    boot(k)=statfun(x(randi(stream,n,n,1),:));
end
assert(all(isfinite(boot)));
alpha=(1-level)/2;
switch lower(char(method))
    case 'percentile'
        ci=quantile(boot,[alpha 1-alpha]);
    case 'basic'
        ci=2*theta-fliplr(quantile(boot,[alpha 1-alpha]));
    case 'bca'
        jack=zeros(n,1);
        for j=1:n
            keep=true(n,1); keep(j)=false;
            jack(j)=statfun(x(keep,:));
        end
        u=mean(jack)-jack;
        denom=6*sum(u.^2)^(3/2);
        if denom==0, accel=0; else, accel=sum(u.^3)/denom; end
        p=(sum(boot<theta)+.5*sum(boot==theta))/B;
        p=max(1/(2*B),min(1-1/(2*B),p));
        z0=-sqrt(2)*erfcinv(2*p);
        z=-sqrt(2)*erfcinv(2*[alpha 1-alpha]);
        q=.5*erfc(-(z0+(z0+z)./(1-accel*(z0+z)))/sqrt(2));
        assert(all(isfinite(q)));
        ci=quantile(boot,q);
    otherwise
        error('Unknown bootstrap method.');
end
end

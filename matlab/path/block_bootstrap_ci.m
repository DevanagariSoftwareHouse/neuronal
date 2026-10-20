function [ci,theta,boot] = block_bootstrap_ci(x,statfun,L,B,level,seed,stationary)
%BLOCK_BOOTSTRAP_CI Draft circular moving-block/stationary bootstrap.
% Ordered observations in rows; synchronous channels in columns.
% Stationary scheme: Politis & Romano (1994).
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%     statfun — function handle that computes the requested statistic.
%     L — the l value; expected shape, units, and constraints are stated in the notes above.
%     B — number of bootstrap/permutation/surrogate draws.
%     level — confidence level between 0 and 1.
%     seed — random-number generator seed.
%     stationary — the stationary value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     ci — confidence interval (one row per statistic, lower and upper limits in columns).
%     theta — the returned value; see the summary above for meaning and units.
%     boot — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [ci, theta, boot] = block_bootstrap_ci(x, statfun, L, B, level, seed, stationary);
%
if nargin<2||isempty(statfun), statfun=@(a)mean(a,1); end
if nargin<3||isempty(L), L=round(sqrt(size(x,1))); end
if nargin<4||isempty(B), B=2000; end
if nargin<5||isempty(level), level=.95; end
if nargin<6||isempty(seed), seed=42; end
if nargin<7||isempty(stationary), stationary=false; end
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1); assert(n>=3&&L>=1&&L<=n&&B>=20&&level>0&&level<1);
theta=reshape(statfun(x),1,[]);
stream=RandStream('mt19937ar','Seed',seed);
boot=zeros(B,numel(theta));
for k=1:B
    if stationary
        idx=zeros(n,1); idx(1)=randi(stream,n);
        for j=2:n
            if rand(stream)<1/L
                idx(j)=randi(stream,n);
            else
                idx(j)=mod(idx(j-1),n)+1;
            end
        end
    else
        starts=randi(stream,n,ceil(n/L),1);
        idx=reshape(mod(starts+(0:L-1)-1,n)+1,[],1);
        idx=idx(1:n);
    end
    v=reshape(statfun(x(idx,:)),1,[]);
    assert(numel(v)==numel(theta)&&all(isfinite(v)));
    boot(k,:)=v;
end
ci=quantile(boot,[(1-level)/2,(1+level)/2],1);
end

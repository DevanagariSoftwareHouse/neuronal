function [ci,theta,boot] = block_bootstrap_ci(x,statfun,L,B,level,seed,stationary)
%BLOCK_BOOTSTRAP_CI Draft circular moving-block/stationary bootstrap.
% Ordered observations in rows; synchronous channels in columns.
% Stationary scheme: Politis & Romano (1994).
%
%   SYNTAX
%     [ci,theta,boot] = block_bootstrap_ci(x,statfun,L,B,level,seed,stationary)
%
%   INPUTS
%     x: Finite ordered observations-by-features matrix, at least 3 rows.
%     statfun: Function accepting a resampled matrix and returning a fixed-size statistic;
%       default column means.
%     L: Block length, or expected stationary-block length, in rows; default
%       round(sqrt(size(x,1))).
%     B: Integer replicate count >=20; default 2000.
%     level: Confidence probability in (0,1); default 0.95.
%     seed: Local mt19937ar seed; default 42.
%     stationary: true selects geometric block lengths; false (default) selects the fixed-block
%       branch.
%
%   OUTPUTS
%     ci: 2-by-P percentile bounds, lower then upper.
%     theta: 1-by-P original statistic.
%     boot: B-by-P bootstrap statistics.
%
%   EXAMPLE
%     rng(7); x = filter(1,[1 -0.7],randn(200,1));
%     [ci, theta, boot] = block_bootstrap_ci(x,@mean,10,500,0.95,7,true);
%     % L=10 is an illustration; choose a dependence scale for the data.
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

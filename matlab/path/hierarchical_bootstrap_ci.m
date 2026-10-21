function [ci,theta,boot] = hierarchical_bootstrap_ci(groups,statfun,B,level,seed)
%HIERARCHICAL_BOOTSTRAP_CI Draft nested resampling: animals then trials.
% groups{animal}: trials x features. Statistic accepts a cell array.
% For clustered units within animals, extend to an additional level.
%
%   SYNTAX
%     [ci,theta,boot] = hierarchical_bootstrap_ci(groups,statfun,B,level,seed)
%
%   INPUTS
%     groups: Cell array of at least 2 animals/groups, each a nonempty finite
%       trials-by-features matrix.
%     statfun: Function accepting the resampled cell array; default mean of per-group means
%       over all elements.
%     B: Integer replicate count >=20; default 2000.
%     level: Confidence probability in (0,1); default 0.95.
%     seed: Local mt19937ar seed; default 42.
%
%   OUTPUTS
%     ci: 2-by-P percentile lower/upper bounds.
%     theta: 1-by-P original statistic.
%     boot: B-by-P statistics from resampling groups, then rows within selected groups.
%
%   EXAMPLE
%     rng(7); groups = {randn(10,1),randn(12,1)+1,randn(8,1)};
%     [ci, theta, boot] = hierarchical_bootstrap_ci(groups,[],500,0.95,7);
%     % The default gives each animal equal weight despite unequal trial counts.
%
if nargin<2||isempty(statfun)
    statfun=@(g)mean(cellfun(@(a)mean(a(:)),g));
end
if nargin<3||isempty(B), B=2000; end
if nargin<4||isempty(level), level=.95; end
if nargin<5||isempty(seed), seed=42; end
assert(iscell(groups)&&numel(groups)>=2&&B>=20&&level>0&&level<1);
for j=1:numel(groups)
    a=groups{j};
    assert(isnumeric(a)&&ismatrix(a)&&~isempty(a)&&all(isfinite(a(:))));
end
theta=reshape(statfun(groups),1,[]);
ng=numel(groups); stream=RandStream('mt19937ar','Seed',seed);
boot=zeros(B,numel(theta));
for k=1:B
    selected=randi(stream,ng,ng,1); sample=cell(ng,1);
    for j=1:ng
        a=groups{selected(j)}; n=size(a,1);
        sample{j}=a(randi(stream,n,n,1),:);
    end
    v=reshape(statfun(sample),1,[]);
    assert(numel(v)==numel(theta)&&all(isfinite(v)));
    boot(k,:)=v;
end
ci=quantile(boot,[(1-level)/2,(1+level)/2],1);
end

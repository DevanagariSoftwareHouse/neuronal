function [ci,theta,boot] = hierarchical_bootstrap_ci(groups,statfun,B,level,seed)
%HIERARCHICAL_BOOTSTRAP_CI Draft nested resampling: animals then trials.
% groups{animal}: trials x features. Statistic accepts a cell array.
% For clustered units within animals, extend to an additional level.
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

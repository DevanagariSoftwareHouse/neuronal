function [ci,theta,boot] = hierarchical_bootstrap_ci(groups,statfun,B,level,seed)
%HIERARCHICAL_BOOTSTRAP_CI Nested bootstrap for independent top-level units.
% SIGNATURE: [ci,theta,boot] = hierarchical_bootstrap_ci(groups,statfun,B,level,seed)
% INPUTS:
%   groups  cell [g x 1] or [1 x g], g>=2 independent top-level units;
%           each element is finite numeric [n x d] or nested cell levels,
%           whose leaves are numeric [n x d] with observations in rows
%   statfun function_handle @(groups)->double [1 x k], must support the
%           exact nesting of groups; default only supports numeric leaves
%   B       integer scalar >=20, replicates (default 2000)
%   level   double scalar in (0,1), CI coverage (default .95)
%   seed    nonnegative integer scalar, RNG seed (default 42)
% OUTPUTS:
%   ci      double [2 x k], lower/upper percentile bounds
%   theta   double [1 x k], statistic of original nested data
%   boot    double [B x k], resampled statistics
% Legacy: groups{animal} = trials x features; resample rows within animals.
% General: groups{animal}{session}{cluster} = observations x features.
% Each cell level is resampled with replacement, recursively. Use a
% statistic that understands the nested structure and scientific estimand.
% Do not treat crossed trial/unit factors as nested without justification.
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
validate_node(groups);
theta=reshape(statfun(groups),1,[]);
assert(all(isfinite(theta)));
ng=numel(groups); stream=RandStream('mt19937ar','Seed',seed);
boot=zeros(B,numel(theta));
for k=1:B
    selected=randi(stream,ng,ng,1);
    sample=cell(ng,1);
    for j=1:ng
        sample{j}=resample_node(groups{selected(j)},stream);
    end
    v=reshape(statfun(sample),1,[]);
    assert(numel(v)==numel(theta)&&all(isfinite(v)));
    boot(k,:)=v;
end
ci=quantile(boot,[(1-level)/2,(1+level)/2],1);
end

function validate_node(a)
if iscell(a)
    assert(~isempty(a),'Empty nested level.');
    for j=1:numel(a), validate_node(a{j}); end
else
    assert(isnumeric(a)&&ismatrix(a)&&~isempty(a)&&all(isfinite(a(:))));
end
end

function out=resample_node(a,stream)
if iscell(a)
    n=numel(a); idx=randi(stream,n,n,1); out=cell(n,1);
    for j=1:n, out{j}=resample_node(a{idx(j)},stream); end
else
    n=size(a,1); out=a(randi(stream,n,n,1),:);
end
end

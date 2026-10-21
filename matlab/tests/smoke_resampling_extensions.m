function smoke_resampling_extensions()
%SMOKE_RESAMPLING_EXTENSIONS Deterministic synthetic sanity checks.
% Run after addpath('matlab/path'). Coverage is not established by smoke tests.
x=(1:8)';
[ci,t,d,w]=bayesian_bootstrap_ci(x,[],300,.95,17);
assert(isequal(size(ci),[2 1])&&numel(d)==300);
assert(abs(t-mean(x))<1e-12);
assert(max(abs(sum(w,1)-1))<1e-12&&all(w(:)>0));
[~,~,d2]=bayesian_bootstrap_ci(x,[],300,.95,17);
assert(isequal(d,d2));
[ci,t,d]=balanced_bootstrap_ci(x,[],200,.95,17);
assert(isequal(size(ci),[2 1])&&abs(mean(d)-t)<1e-12);
X=[ones(30,1),(1:30)']; y=X*[2;3]+sin((1:30)');
[ci,b,d]=wild_bootstrap_ci(X,y,200,.95,17,'rademacher');
assert(isequal(size(ci),[2 2])&&isequal(size(d),[200 2]));
assert(max(abs(b-(X\y)))<1e-12);
[~,~,m]=wild_bootstrap_ci(X,y,200,.95,17,'mammen');
assert(isequal(size(m),[200 2])&&all(isfinite(m(:))));
groups={{[1;2],[3;4]}, {[5;6],[7;8]}};
stat=@(g)mean(cellfun(@(a)mean(cellfun(@mean,a)),g));
[ci,t,d]=hierarchical_bootstrap_ci(groups,stat,200,.95,17);
assert(isequal(size(ci),[2 1])&&numel(d)==200&&isfinite(t));
legacy={[1;2;3],[4;5;6]};
[ci,~,d]=hierarchical_bootstrap_ci(legacy,[],200,.95,17);
assert(isequal(size(ci),[2 1])&&numel(d)==200);
disp('Resampling extension smoke tests passed.');
end

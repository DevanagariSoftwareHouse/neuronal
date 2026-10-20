function folds = blocked_cross_validation(n,k,gap)
%BLOCKED_CROSS_VALIDATION Contiguous held-out folds with exclusion gap.
% Returns train/test index vectors; model fitting is caller responsibility.
%
%   SYNTAX
%     folds = blocked_cross_validation(n,k,gap)
%
%   INPUTS
%     n: Integer number of ordered observations.
%     k: Integer number of folds, 2 <= k <= n.
%     gap: Nonnegative integer excluded rows on each side of a test block; default 0.
%
%   OUTPUTS
%     folds: k-by-1 cell array; each struct has train/test column indices (1-based).
%
%   EXAMPLE
%     folds = blocked_cross_validation(100,5,3);
%     train_rows = folds{1}.train; test_rows = folds{1}.test;
%     % Fit preprocessing only on train_rows; gap rows are not training data.
%
if nargin<3||isempty(gap), gap=0; end
assert(n>=k&&k>=2&&k==floor(k)&&gap>=0&&gap==floor(gap));
edges=round(linspace(0,n,k+1)); folds=cell(k,1);
for j=1:k
    test=(edges(j)+1:edges(j+1))';
    lo=max(1,test(1)-gap); hi=min(n,test(end)+gap);
    train=setdiff((1:n)',(lo:hi)');
    assert(~isempty(train),'No training data after gap exclusion.');
    folds{j}=struct('train',train,'test',test);
end
end

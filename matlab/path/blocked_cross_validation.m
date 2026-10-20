function folds = blocked_cross_validation(n,k,gap)
%BLOCKED_CROSS_VALIDATION Contiguous held-out folds with exclusion gap.
% Returns train/test index vectors; model fitting is caller responsibility.
%
%   SIGNATURE DESCRIPTION
%     n — the n value; expected shape, units, and constraints are stated in the notes above.
%     k — the k value; expected shape, units, and constraints are stated in the notes above.
%     gap — the gap value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     folds — cell array of train/test index sets.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     folds = blocked_cross_validation(n, k, gap);
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

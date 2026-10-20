function folds = group_cross_validation(group,k)
%GROUP_CROSS_VALIDATION Group-disjoint K-fold splits, e.g. by animal.
% No animal may occur in both train and test within a fold.
%
%   SIGNATURE DESCRIPTION
%     group — group identifier for each observation.
%     k — the k value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     folds — cell array of train/test index sets.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     folds = group_cross_validation(group, k);
%
[unique_groups,~,idx]=unique(group(:),'stable');
g=numel(unique_groups);
if nargin<2||isempty(k), k=g; end
assert(k>=2&&k<=g&&k==floor(k));
order=randperm(g); foldid=zeros(g,1);
foldid(order)=mod(0:g-1,k)+1;
folds=cell(k,1);
for j=1:k
    test=find(ismember(idx,find(foldid==j)));
    train=find(~ismember(idx,find(foldid==j)));
    folds{j}=struct('train',train,'test',test,'test_groups',unique_groups(foldid==j));
end
end

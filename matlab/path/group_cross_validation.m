function folds = group_cross_validation(group,k)
%GROUP_CROSS_VALIDATION Group-disjoint K-fold splits, e.g. by animal.
% No animal may occur in both train and test within a fold.
%
%   SYNTAX
%     folds = group_cross_validation(group,k)
%
%   INPUTS
%     group: Vector of group identifiers, one per observation.
%     k: Integer fold count from 2 to number of distinct groups; default leave-one-group-out.
%
%   OUTPUTS
%     folds: k-by-1 cell array of structs with train/test observation indices and test_groups.
%
%   EXAMPLE
%     rng(7); group = repelem((1:6)',5);
%     folds = group_cross_validation(group,3);
%     % No group appears in both folds{1}.train and folds{1}.test.
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

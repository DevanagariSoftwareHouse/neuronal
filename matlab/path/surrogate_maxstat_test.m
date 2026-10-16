function result = surrogate_maxstat_test(observed,null,tail)
%SURROGATE_MAXSTAT_TEST Familywise max-statistic corrected p-values.
% observed: 1 x features; null: B x features from JOINT null draws.
% Absolute values for 'two-sided' assume zero-centered null statistics.
if nargin<3||isempty(tail), tail='right'; end
observed=reshape(observed,1,[]);
assert(isnumeric(null)&&ismatrix(null)&&size(null,2)==numel(observed));
assert(all(isfinite(null(:)))&&all(isfinite(observed)));
switch lower(char(tail))
    case 'right', transformed=null; target=observed;
    case 'left', transformed=-null; target=-observed;
    case 'two-sided', transformed=abs(null); target=abs(observed);
    otherwise, error('Unknown tail');
end
maxnull=max(transformed,[],2);
p=zeros(size(target));
for j=1:numel(target)
    p(j)=(1+sum(maxnull>=target(j)))/(size(null,1)+1);
end
result=struct('p_corrected',p,'max_null',maxnull,'observed',observed);
end

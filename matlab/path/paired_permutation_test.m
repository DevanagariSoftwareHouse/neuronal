function result = paired_permutation_test(a,b,statfun,B,tail)
%PAIRED_PERMUTATION_TEST Random sign flips of matched differences.
% Sign symmetry under H0 is required for a valid sign-flip test.
if nargin<3||isempty(statfun), statfun=@(d)mean(d,1); end
if nargin<4||isempty(B), B=999; end
if nargin<5||isempty(tail), tail='two-sided'; end
assert(isnumeric(a)&&isequal(size(a),size(b))&&all(isfinite(a(:)))&&all(isfinite(b(:))));
d=b-a; n=size(d,1); assert(n>=2&&B>=19&&B==floor(B));
obs=reshape(statfun(d),1,[]); null=zeros(B,numel(obs));
for k=1:B
    signs=2*(rand(n,1)>.5)-1;
    null(k,:)=reshape(statfun(bsxfun(@times,d,signs)),1,[]);
end
switch lower(char(tail))
    case 'right', extreme=bsxfun(@ge,null,obs);
    case 'left', extreme=bsxfun(@le,null,obs);
    case 'two-sided', extreme=bsxfun(@ge,abs(null),abs(obs));
    otherwise, error('Unknown tail');
end
result=struct('observed',obs,'null',null,'p',(1+sum(extreme,1))/(B+1));
end

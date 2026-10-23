function result = permutation_test(a,b,statfun,B,tail)
%PERMUTATION_TEST Two-sample label permutation for exchangeable rows.
% Statistic receives (a,b) and returns scalar. Independent groups only.
%
%   SYNTAX
%     result = permutation_test(a,b,statfun,B,tail)
%
%   INPUTS
%     a: Nonempty finite group-A observations-by-features matrix.
%     b: Nonempty finite group-B matrix with matching feature columns.
%     statfun: Function (a,b) returning a finite scalar; default mean(a(:))-mean(b(:)).
%     B: Integer permutations >=19; default 999.
%     tail: two-sided (default), right or left.
%
%   OUTPUTS
%     result: Struct with observed scalar, null (B-by-1) and plus-one p-value.
%
%   EXAMPLE
%     rng(7); a = randn(20,1)+0.5; b = randn(25,1);
%     result = permutation_test(a,b,[],199,'two-sided');
%     % The default statistic is A-B, unlike paired functions using B-A.
%
if nargin<3||isempty(statfun), statfun=@(x,y)mean(x(:))-mean(y(:)); end
if nargin<4||isempty(B), B=999; end
if nargin<5||isempty(tail), tail='two-sided'; end
assert(isnumeric(a)&&isnumeric(b)&&size(a,2)==size(b,2));
assert(~isempty(a)&&~isempty(b)&&all(isfinite(a(:)))&&all(isfinite(b(:))));
assert(B>=19&&B==floor(B));
na=size(a,1); pool=[a;b]; n=size(pool,1);
obs=statfun(a,b); assert(isscalar(obs)&&isfinite(obs));
null=zeros(B,1);
for k=1:B
    p=randperm(n);
    null(k)=statfun(pool(p(1:na),:),pool(p(na+1:end),:));
end
switch lower(char(tail))
    case 'right', extreme=null>=obs;
    case 'left', extreme=null<=obs;
    case 'two-sided', extreme=abs(null)>=abs(obs);
    otherwise, error('Unknown tail');
end
result=struct('observed',obs,'null',null,'p',(sum(extreme)+1)/(B+1));
end

function result = permutation_test(a,b,statfun,B,tail)
%PERMUTATION_TEST Two-sample label permutation for exchangeable rows.
% Statistic receives (a,b) and returns scalar. Independent groups only.
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

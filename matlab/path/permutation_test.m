function result = permutation_test(a,b,statfun,B,tail)
%PERMUTATION_TEST Two-sample label permutation for exchangeable rows.
% Statistic receives (a,b) and returns scalar. Independent groups only.
%
%   SIGNATURE DESCRIPTION
%     a — the a value; expected shape, units, and constraints are stated in the notes above.
%     b — the b value; expected shape, units, and constraints are stated in the notes above.
%     statfun — function handle that computes the requested statistic.
%     B — number of bootstrap/permutation/surrogate draws.
%     tail — the tail value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     result — result structure containing the estimates and diagnostics described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     result = permutation_test(a, b, statfun, B, tail);
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

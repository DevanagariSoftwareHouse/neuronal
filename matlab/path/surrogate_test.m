function result = surrogate_test(data,statfun,surrogatefun,B,tail)
%SURROGATE_TEST Monte Carlo surrogate hypothesis test.
% statfun(data) must return scalar. surrogatefun(data) generates one null draw.
% tail: 'right', 'left', 'two-sided' (two-sided uses |T| around zero).
% Exact Monte Carlo interpretation requires exchangeability under H0.
if nargin<4||isempty(B), B=999; end
if nargin<5||isempty(tail), tail='right'; end
assert(B>=19&&B==floor(B));
observed=statfun(data); assert(isscalar(observed)&&isfinite(observed));
null=zeros(B,1);
for k=1:B
    null(k)=statfun(surrogatefun(data));
end
assert(all(isfinite(null)));
switch lower(char(tail))
    case 'right', extreme=null>=observed;
    case 'left', extreme=null<=observed;
    case 'two-sided', extreme=abs(null)>=abs(observed);
    otherwise, error('Unknown tail');
end
result=struct('observed',observed,'null',null, ...
    'p',(1+sum(extreme))/(B+1),'tail',tail,'draws',B);
end

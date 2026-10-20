function result = surrogate_test(data,statfun,surrogatefun,B,tail)
%SURROGATE_TEST Monte Carlo surrogate hypothesis test.
% statfun(data) must return scalar. surrogatefun(data) generates one null draw.
% tail: 'right', 'left', 'two-sided' (two-sided uses |T| around zero).
% Exact Monte Carlo interpretation requires exchangeability under H0.
%
%   SYNTAX
%     result = surrogate_test(data,statfun,surrogatefun,B,tail)
%
%   INPUTS
%     data: Dataset accepted by both callbacks.
%     statfun: Function statfun(data) returning a finite scalar.
%     surrogatefun: Function surrogatefun(data) generating one null dataset.
%     B: Integer null draws >=19; default 999.
%     tail: right (default), left, or two-sided (absolute values around zero).
%
%   OUTPUTS
%     result: Struct with observed, null (B-by-1), p (plus-one p-value), tail and draws.
%
%   EXAMPLE
%     rng(7); x = randn(80,1); data = [x,x+randn(80,1)];
%     statfun = @(z) mean(z(:,1).*z(:,2));
%     shuffle = @(z) [z(:,1),z(randperm(size(z,1)),2)];
%     result = surrogate_test(data,statfun,shuffle,199,'right');
%     % This null destroys row pairing and assumes rows are exchangeable.
%
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

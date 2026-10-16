function result = monte_carlo_null_test(observed,statfun,nullgen,B,tail)
%MONTE_CARLO_NULL_TEST Parametric Monte Carlo null with simulated datasets.
% nullgen() generates a full dataset under the specified H0.
if nargin<4||isempty(B), B=999; end
if nargin<5||isempty(tail), tail='right'; end
assert(B>=19&&B==floor(B));
obs=statfun(observed); assert(isscalar(obs)&&isfinite(obs));
null=zeros(B,1);
for k=1:B, null(k)=statfun(nullgen()); end
assert(all(isfinite(null)));
switch lower(char(tail))
    case 'right', extreme=null>=obs;
    case 'left', extreme=null<=obs;
    case 'two-sided', extreme=abs(null)>=abs(obs);
    otherwise, error('Unknown tail');
end
result=struct('observed',obs,'null',null,'p',(1+sum(extreme))/(B+1));
end

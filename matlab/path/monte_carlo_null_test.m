function result = monte_carlo_null_test(observed,statfun,nullgen,B,tail)
%MONTE_CARLO_NULL_TEST Parametric Monte Carlo null with simulated datasets.
% nullgen() generates a full dataset under the specified H0.
%
%   SYNTAX
%     result = monte_carlo_null_test(observed,statfun,nullgen,B,tail)
%
%   INPUTS
%     observed: Dataset accepted by statfun.
%     statfun: Function mapping a dataset to one finite scalar.
%     nullgen: Zero-argument function generating a complete dataset under H0.
%     B: Integer null draws >=19; default 999.
%     tail: right (default), left, or two-sided (absolute-value comparison).
%
%   OUTPUTS
%     result: Struct with observed (scalar statistic), null (B-by-1) and p (plus-one Monte
%       Carlo p-value).
%
%   EXAMPLE
%     rng(7); x = 0.5+randn(30,1);
%     result = monte_carlo_null_test(x,@mean,@()randn(30,1),199,'right');
%     % H0 here specifies independent N(0,1) observations.
%
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

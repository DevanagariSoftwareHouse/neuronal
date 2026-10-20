function [ci,delta,boot] = paired_difference_ci(a,b,B,level,method,seed)
%PAIRED_DIFFERENCE_CI Draft bootstrap for matched differences B-A.
% Rows must be independent matched experimental units.
%
%   SIGNATURE DESCRIPTION
%     a — the a value; expected shape, units, and constraints are stated in the notes above.
%     b — the b value; expected shape, units, and constraints are stated in the notes above.
%     B — number of bootstrap/permutation/surrogate draws.
%     level — confidence level between 0 and 1.
%     method — the method value; expected shape, units, and constraints are stated in the notes above.
%     seed — random-number generator seed.
%   RETURNS
%     ci — confidence interval (one row per statistic, lower and upper limits in columns).
%     delta — the returned value; see the summary above for meaning and units.
%     boot — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [ci, delta, boot] = paired_difference_ci(a, b, B, level, method, seed);
%
if nargin<3, B=[]; end
if nargin<4, level=[]; end
if nargin<5, method=[]; end
if nargin<6, seed=[]; end
assert(isnumeric(a)&&isnumeric(b)&&isequal(size(a),size(b)));
assert(isvector(a)&&all(isfinite(a(:)))&&all(isfinite(b(:))));
[ci,delta,boot]=bootstrap_ci(b(:)-a(:),@mean,B,level,method,seed);
end

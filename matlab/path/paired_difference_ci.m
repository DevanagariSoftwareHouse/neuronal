function [ci,delta,boot] = paired_difference_ci(a,b,B,level,method,seed)
%PAIRED_DIFFERENCE_CI Draft bootstrap for matched differences B-A.
% Rows must be independent matched experimental units.
%
%   SYNTAX
%     [ci,delta,boot] = paired_difference_ci(a,b,B,level,method,seed)
%
%   INPUTS
%     a: Finite vector of before/condition-A measurements, >=3 matched units.
%     b: Same-sized finite vector of after/condition-B measurements.
%     B: Integer bootstrap draws >=20; default 2000.
%     level: Confidence probability in (0,1); default 0.95.
%     method: percentile (default), basic or bca.
%     seed: Local mt19937ar seed; default 42.
%
%   OUTPUTS
%     ci: 1-by-2 bounds for the mean paired B-A difference.
%     delta: Scalar original mean B-A.
%     boot: B-by-1 bootstrap mean differences.
%
%   EXAMPLE
%     a = [5;7;6;8;4]; b = a+[1;2;0;1;3];
%     [ci, delta, boot] = paired_difference_ci(a,b,500,0.95,'percentile',7);
%     % Pair identities are preserved by resampling differences.
%
if nargin<3, B=[]; end
if nargin<4, level=[]; end
if nargin<5, method=[]; end
if nargin<6, seed=[]; end
assert(isnumeric(a)&&isnumeric(b)&&isequal(size(a),size(b)));
assert(isvector(a)&&all(isfinite(a(:)))&&all(isfinite(b(:))));
[ci,delta,boot]=bootstrap_ci(b(:)-a(:),@mean,B,level,method,seed);
end

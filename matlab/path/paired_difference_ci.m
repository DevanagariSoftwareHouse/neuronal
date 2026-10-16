function [ci,delta,boot] = paired_difference_ci(a,b,B,level,method,seed)
%PAIRED_DIFFERENCE_CI Draft bootstrap for matched differences B-A.
% Rows must be independent matched experimental units.
if nargin<3, B=[]; end
if nargin<4, level=[]; end
if nargin<5, method=[]; end
if nargin<6, seed=[]; end
assert(isnumeric(a)&&isnumeric(b)&&isequal(size(a),size(b)));
assert(isvector(a)&&all(isfinite(a(:)))&&all(isfinite(b(:))));
[ci,delta,boot]=bootstrap_ci(b(:)-a(:),@mean,B,level,method,seed);
end

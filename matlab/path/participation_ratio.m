function dimension = participation_ratio(activity)
%PARTICIPATION_RATIO Covariance effective dimensionality: tr(C)^2/tr(C^2).
% Used in dimensionality analyses; raw variance differences influence result.
%
%   SYNTAX
%     dimension = participation_ratio(activity)
%
%   INPUTS
%     activity: Finite observations-by-units matrix, >=2 rows; columns are centered internally.
%
%   OUTPUTS
%     dimension: Scalar covariance participation ratio; NaN for zero centered variance.
%
%   EXAMPLE
%     rng(7); activity = randn(100,5);
%     dimension = participation_ratio(activity);
%     % Unequal unit variances affect this effective dimension.
%
x=double(activity);
assert(ismatrix(x) && size(x,1)>=2 && all(isfinite(x(:))));
x=bsxfun(@minus,x,mean(x,1));
s=svd(x,'econ').^2;
if sum(s.^2)==0, dimension=NaN; return; end
dimension=sum(s)^2/sum(s.^2);
end

function [ci,out] = jackknife_ci(x,statfun,level)
%JACKKNIFE_CI Normal-approximation jackknife confidence intervals.
% Requires independent rows and an approximately normal estimator.
if nargin<2, statfun=[]; end
if nargin<3||isempty(level), level=.95; end
assert(level>0&&level<1);
out=jackknife_estimate(x,statfun);
z=-sqrt(2)*erfcinv(1+level);
ci=[out.bias_corrected-z*out.se;out.bias_corrected+z*out.se];
end

function [ci,out] = jackknife_ci(x,statfun,level)
%JACKKNIFE_CI Normal-approximation jackknife confidence intervals.
% Requires independent rows and an approximately normal estimator.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%     statfun — function handle that computes the requested statistic.
%     level — confidence level between 0 and 1.
%   RETURNS
%     ci — confidence interval (one row per statistic, lower and upper limits in columns).
%     out — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [ci, out] = jackknife_ci(x, statfun, level);
%
if nargin<2, statfun=[]; end
if nargin<3||isempty(level), level=.95; end
assert(level>0&&level<1);
out=jackknife_estimate(x,statfun);
z=-sqrt(2)*erfcinv(1+level);
ci=[out.bias_corrected-z*out.se;out.bias_corrected+z*out.se];
end

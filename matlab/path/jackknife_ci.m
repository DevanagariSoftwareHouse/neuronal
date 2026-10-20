function [ci,out] = jackknife_ci(x,statfun,level)
%JACKKNIFE_CI Normal-approximation jackknife confidence intervals.
% Requires independent rows and an approximately normal estimator.
%
%   SYNTAX
%     [ci,out] = jackknife_ci(x,statfun,level)
%
%   INPUTS
%     x: Finite independent-observations-by-features matrix, at least 3 rows.
%     statfun: Fixed-size statistic function; default column means.
%     level: Confidence probability in (0,1); default 0.95.
%
%   OUTPUTS
%     ci: 2-by-P normal-approximation bounds around the bias-corrected estimate.
%     out: jackknife_estimate result with estimate, leave_one_out, bias, se and bias_corrected.
%
%   EXAMPLE
%     x = [1;2;4;5;7];
%     [ci, out] = jackknife_ci(x,@mean,0.95);
%     % The interval uses a normal approximation, not a t quantile.
%
if nargin<2, statfun=[]; end
if nargin<3||isempty(level), level=.95; end
assert(level>0&&level<1);
out=jackknife_estimate(x,statfun);
z=-sqrt(2)*erfcinv(1+level);
ci=[out.bias_corrected-z*out.se;out.bias_corrected+z*out.se];
end

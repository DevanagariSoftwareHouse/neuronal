function [mean_angle,resultant_length] = circular_mean(angles,weights)
%CIRCULAR_MEAN Weighted circular mean in radians, Berens (2009) CircStat.
% DOI 10.18637/jss.v031.i10. Finite angles and nonnegative weights only.
% Mean undefined when resultant is numerically indistinguishable from 0.
%
%   SYNTAX
%     [mean_angle,resultant_length] = circular_mean(angles,weights)
%
%   INPUTS
%     angles: Nonempty finite angles in radians, flattened to a vector.
%     weights: Matching nonnegative weights with positive sum; default ones(size(angles)).
%
%   OUTPUTS
%     mean_angle: Scalar circular mean in radians; NaN if resultant <1e-12.
%     resultant_length: Scalar normalized resultant magnitude in [0,1].
%
%   EXAMPLE
%     angles = [-0.2; 0; 0.3];
%     [mu, r] = circular_mean(angles,[1; 2; 1]);
%     % r measures concentration; mu is an angle, not an arithmetic mean.
%
if nargin<2 || isempty(weights), weights=ones(size(angles)); end
a=double(angles(:)); w=double(weights(:));
assert(numel(a)==numel(w) && ~isempty(a));
assert(all(isfinite(a)) && all(isfinite(w)) && all(w>=0) && sum(w)>0);
z=sum(w.*exp(1i*a))/sum(w);
resultant_length=abs(z);
mean_angle=angle(z);
if resultant_length<1e-12, mean_angle=NaN; end
end

function [mean_angle,resultant_length] = circular_mean(angles,weights)
%CIRCULAR_MEAN Weighted circular mean in radians, Berens (2009) CircStat.
% DOI 10.18637/jss.v031.i10. Finite angles and nonnegative weights only.
% Mean undefined when resultant is numerically indistinguishable from 0.
%
%   SIGNATURE DESCRIPTION
%     angles — the angles value; expected shape, units, and constraints are stated in the notes above.
%     weights — nonnegative observation weights.
%   RETURNS
%     mean_angle — the returned value; see the summary above for meaning and units.
%     resultant_length — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [mean_angle, resultant_length] = circular_mean(angles, weights);
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

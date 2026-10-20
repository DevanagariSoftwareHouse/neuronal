function [referenced,common] = common_median_reference(recording)
%COMMON_MEDIAN_REFERENCE Subtract median across channels at each sample.
% Inputs channels x samples; robust common-mode suppression.
% Shared neural activity can also be attenuated. Compare reference schemes.
%
%   SIGNATURE DESCRIPTION
%     recording — multichannel recording matrix; channel/sample orientation is stated above.
%   RETURNS
%     referenced — the returned value; see the summary above for meaning and units.
%     common — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [referenced, common] = common_median_reference(recording);
%
assert(isnumeric(recording) && ismatrix(recording) && ...
    size(recording,1)>=2 && all(isfinite(recording(:))));
common=median(double(recording),1);
referenced=bsxfun(@minus,double(recording),common);
end

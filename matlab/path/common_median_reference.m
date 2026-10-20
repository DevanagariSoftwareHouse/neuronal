function [referenced,common] = common_median_reference(recording)
%COMMON_MEDIAN_REFERENCE Subtract median across channels at each sample.
% Inputs channels x samples; robust common-mode suppression.
% Shared neural activity can also be attenuated. Compare reference schemes.
%
%   SYNTAX
%     [referenced,common] = common_median_reference(recording)
%
%   INPUTS
%     recording: Finite channels-by-samples numeric matrix with at least 2 channels.
%
%   OUTPUTS
%     referenced: Same-sized double matrix after subtracting the channel median.
%     common: 1-by-samples median signal in recording units.
%
%   EXAMPLE
%     recording = randn(4,1000);
%     [referenced, common] = common_median_reference(recording);
%     % Compare both signals to assess removed common activity.
%
assert(isnumeric(recording) && ismatrix(recording) && ...
    size(recording,1)>=2 && all(isfinite(recording(:))));
common=median(double(recording),1);
referenced=bsxfun(@minus,double(recording),common);
end

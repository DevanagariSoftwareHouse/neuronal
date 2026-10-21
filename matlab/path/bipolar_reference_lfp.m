function [bipolar,midpoint_depth] = bipolar_reference_lfp(potential,depth_m)
%BIPOLAR_REFERENCE_LFP Adjacent laminar voltage differences.
% Channels must be ordered by physical depth and share consistent units.
% Difference is not itself a CSD estimate.
%
%   SYNTAX
%     [bipolar,midpoint_depth] = bipolar_reference_lfp(potential,depth_m)
%
%   INPUTS
%     potential: Finite channels-by-samples matrix with at least 2 channels.
%     depth_m: Strictly increasing channel depths in metres, one per row.
%
%   OUTPUTS
%     bipolar: (channels-1)-by-samples differences, deeper minus shallower.
%     midpoint_depth: Column of adjacent-pair midpoint depths in metres.
%
%   EXAMPLE
%     potential = randn(4,1000); depths = (0:3)'*100e-6;
%     [bipolar, midpoint_depth] = bipolar_reference_lfp(potential,depths);
%     % bipolar(1,:) equals potential(2,:)-potential(1,:).
%
x=double(potential); z=double(depth_m(:));
assert(ismatrix(x) && size(x,1)>=2 && numel(z)==size(x,1));
assert(all(isfinite(x(:))) && all(isfinite(z)) && all(diff(z)>0));
bipolar=diff(x,1,1);
midpoint_depth=(z(1:end-1)+z(2:end))/2;
end

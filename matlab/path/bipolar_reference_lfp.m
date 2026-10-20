function [bipolar,midpoint_depth] = bipolar_reference_lfp(potential,depth_m)
%BIPOLAR_REFERENCE_LFP Adjacent laminar voltage differences.
% Channels must be ordered by physical depth and share consistent units.
% Difference is not itself a CSD estimate.
%
%   SIGNATURE DESCRIPTION
%     potential — the potential value; expected shape, units, and constraints are stated in the notes above.
%     depth_m — the depth m value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     bipolar — the returned value; see the summary above for meaning and units.
%     midpoint_depth — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [bipolar, midpoint_depth] = bipolar_reference_lfp(potential, depth_m);
%
x=double(potential); z=double(depth_m(:));
assert(ismatrix(x) && size(x,1)>=2 && numel(z)==size(x,1));
assert(all(isfinite(x(:))) && all(isfinite(z)) && all(diff(z)>0));
bipolar=diff(x,1,1);
midpoint_depth=(z(1:end-1)+z(2:end))/2;
end

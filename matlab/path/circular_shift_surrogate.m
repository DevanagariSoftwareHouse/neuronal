function shifted = circular_shift_surrogate(signal,shift_samples)
%CIRCULAR_SHIFT_SURROGATE Circular temporal shift, preserving sample distribution.
% For PAC/locking nulls choose shifts outside autocorrelation time, avoid edges.
%
%   SIGNATURE DESCRIPTION
%     signal — sampled signal; units and sample axis are given in the notes above.
%     shift_samples — the shift samples value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     shifted — the returned shifted; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     shifted = circular_shift_surrogate(signal, shift_samples);
%
assert(isvector(signal) && ~isempty(signal),'Input must be a vector');
assert(isscalar(shift_samples) && isfinite(shift_samples) && ...
    shift_samples==round(shift_samples),'Shift must be an integer');
shifted=circshift(signal,shift_samples);
end

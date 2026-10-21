function shifted = circular_shift_surrogate(signal,shift_samples)
%CIRCULAR_SHIFT_SURROGATE Circular temporal shift, preserving sample distribution.
% For PAC/locking nulls choose shifts outside autocorrelation time, avoid edges.
%
%   SYNTAX
%     shifted = circular_shift_surrogate(signal,shift_samples)
%
%   INPUTS
%     signal: Nonempty vector.
%     shift_samples: Finite integer circular shift; positive shifts move samples toward higher
%       indices.
%
%   OUTPUTS
%     shifted: Same shape and values as signal with circularly shifted positions.
%
%   EXAMPLE
%     x = (1:10)';
%     y = circular_shift_surrogate(x,3);
%     % y begins [8;9;10;1]; wrapping joins the recording ends.
%
assert(isvector(signal) && ~isempty(signal),'Input must be a vector');
assert(isscalar(shift_samples) && isfinite(shift_samples) && ...
    shift_samples==round(shift_samples),'Shift must be an integer');
shifted=circshift(signal,shift_samples);
end

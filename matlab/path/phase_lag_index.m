function pli = phase_lag_index(phase_difference)
%PHASE_LAG_INDEX Absolute mean sign of phase lag (Stam et al. 2007).
% Zero/antiphase terms contribute zero (they remain in the denominator).
% Sines within 10*eps of zero are rounded to zero to suppress boundary roundoff.
% Nonzero values are not proof of causality.
%
%   SYNTAX
%     pli = phase_lag_index(phase_difference)
%
%   INPUTS
%     phase_difference: Phase-difference vector in radians; nonfinite entries are removed.
%
%   OUTPUTS
%     pli: Scalar absolute mean sign(sin(phase_difference)) in [0,1]; NaN with fewer than 2
%       finite entries.
%
%   EXAMPLE
%     pli = phase_lag_index([0.2;0.3;-0.1;0]);
%     % Zero lag contributes zero but remains in the denominator.
%
p=double(phase_difference(:)); p=p(isfinite(p));
if numel(p)<2, pli=NaN; return; end
lag=sin(p); lag(abs(lag)<=10*eps)=0;
pli=abs(mean(sign(lag)));
end

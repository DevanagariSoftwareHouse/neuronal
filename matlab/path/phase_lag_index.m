function pli = phase_lag_index(phase_difference)
%PHASE_LAG_INDEX Absolute mean sign of phase lag (Stam et al. 2007).
% Zero/antiphase terms contribute zero (they remain in the denominator).
% Sines within 10*eps of zero are rounded to zero to suppress boundary roundoff.
% Nonzero values are not proof of causality.
%
%   SIGNATURE DESCRIPTION
%     phase_difference — the phase difference value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     pli — the returned pli; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     pli = phase_lag_index(phase_difference);
%
p=double(phase_difference(:)); p=p(isfinite(p));
if numel(p)<2, pli=NaN; return; end
lag=sin(p); lag(abs(lag)<=10*eps)=0;
pli=abs(mean(sign(lag)));
end

function pli = phase_lag_index(phase_difference)
%PHASE_LAG_INDEX Absolute mean sign of phase lag (Stam et al. 2007).
% Zero/antiphase terms contribute zero (they remain in the denominator).
% Sines within 10*eps of zero are rounded to zero to suppress boundary roundoff.
% Nonzero values are not proof of causality.
p=double(phase_difference(:)); p=p(isfinite(p));
if numel(p)<2, pli=NaN; return; end
lag=sin(p); lag(abs(lag)<=10*eps)=0;
pli=abs(mean(sign(lag)));
end

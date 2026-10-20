function wpli = weighted_phase_lag_index(cross_spectra)
%WEIGHTED_PHASE_LAG_INDEX Imaginary-cross-spectrum weighted PLI.
% Vinck et al. (2011) weighted PLI (not debiased wPLI).
% Each entry must be a complex cross-spectrum estimate from one segment/trial.
%
%   SIGNATURE DESCRIPTION
%     cross_spectra — the cross spectra value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     wpli — weighted phase-lag index estimate.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     wpli = weighted_phase_lag_index(cross_spectra);
%
z=double(cross_spectra(:));
z=z(isfinite(real(z)) & isfinite(imag(z)));
v=imag(z);
if numel(v)<2 || sum(abs(v))==0, wpli=NaN; return; end
wpli=abs(sum(v))/sum(abs(v));
end

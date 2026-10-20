function wpli = weighted_phase_lag_index(cross_spectra)
%WEIGHTED_PHASE_LAG_INDEX Imaginary-cross-spectrum weighted PLI.
% Vinck et al. (2011) weighted PLI (not debiased wPLI).
% Each entry must be a complex cross-spectrum estimate from one segment/trial.
%
%   SYNTAX
%     wpli = weighted_phase_lag_index(cross_spectra)
%
%   INPUTS
%     cross_spectra: Complex cross-spectrum estimates from independent segments/trials; invalid
%       entries are removed.
%
%   OUTPUTS
%     wpli: Scalar abs(sum(imag(z)))/sum(abs(imag(z))) in [0,1]; NaN for <2 valid entries or
%       zero imaginary magnitude.
%
%   EXAMPLE
%     z = [1+2i; 1+3i; 1-1i];
%     wpli = weighted_phase_lag_index(z);
%     % Returns 4/6; this is the original, not debiased, wPLI estimator.
%
z=double(cross_spectra(:));
z=z(isfinite(real(z)) & isfinite(imag(z)));
v=imag(z);
if numel(v)<2 || sum(abs(v))==0, wpli=NaN; return; end
wpli=abs(sum(v))/sum(abs(v));
end

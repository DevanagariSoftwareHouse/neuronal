function ppc = pairwise_phase_consistency(phase)
%PAIRWISE_PHASE_CONSISTENCY Pairwise phase consistency (PPC).
% Vinck et al. (2010). Unbiased with respect to event count under assumptions.
%
%   SIGNATURE DESCRIPTION
%     phase — phase values in radians.
%   RETURNS
%     ppc — pairwise phase consistency estimate.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     ppc = pairwise_phase_consistency(phase);
%
p=double(phase(:)); p=p(isfinite(p)); n=numel(p);
if n<2, ppc=NaN; return; end
z=exp(1i*p);
ppc=(abs(sum(z))^2-n)/(n*(n-1));
end

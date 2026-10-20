function ppc = pairwise_phase_consistency(phase)
%PAIRWISE_PHASE_CONSISTENCY Pairwise phase consistency (PPC).
% Vinck et al. (2010). Unbiased with respect to event count under assumptions.
%
%   SYNTAX
%     ppc = pairwise_phase_consistency(phase)
%
%   INPUTS
%     phase: Event phases or phase differences in radians; nonfinite values are removed.
%
%   OUTPUTS
%     ppc: Scalar PPC, which can be negative; NaN with fewer than 2 finite phases.
%
%   EXAMPLE
%     phase = [-0.2;0;0.1;0.3];
%     ppc = pairwise_phase_consistency(phase);
%     % Unlike PLV, the finite-sample estimator can fall below zero.
%
p=double(phase(:)); p=p(isfinite(p)); n=numel(p);
if n<2, ppc=NaN; return; end
z=exp(1i*p);
ppc=(abs(sum(z))^2-n)/(n*(n-1));
end

function [significant, threshold, eigenvalues] = assembly_mp_significance(spike_counts)
%ASSEMBLY_MP_SIGNIFICANCE IID Marchenko-Pastur screening of assembly PCs.
%   [SIGNIFICANT,THRESHOLD,EIGENVALUES] = ASSEMBLY_MP_SIGNIFICANCE(COUNTS)
%   compares sample-correlation eigenvalues to (1+sqrt(U/T))^2.
%
%   Inputs: COUNTS T-by-U nonnegative finite spike counts, T>=3;
%   every unit must have nonzero variance.
%   Outputs: SIGNIFICANT logical components, THRESHOLD scalar MP upper edge,
%   EIGENVALUES descending sample covariance eigenvalues of z-scored units.
%
%   Example:
%       rng(5); x = poissrnd(2,500,8);
%       [sig,edge,lambda] = assembly_mp_significance(x);
%
%   Reference: Lopes-dos-Santos et al. (2013), tortlab/Cell-Assembly-Detection.
%   IID MP is a screening heuristic only: temporal dependence, refractory
%   structure and finite T require appropriate surrogate-null checks.
%
    model = assembly_pca(spike_counts);
    eigenvalues = model.eigenvalues(:);
    threshold = model.mp_upper;
    significant = eigenvalues > threshold;
end

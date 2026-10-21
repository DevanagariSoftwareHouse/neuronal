function [strength, preferred_phase, phase_difference] = phase_phase_coupling(phase_a, phase_b, n, m)
%PHASE_PHASE_COUPLING n:m phase synchronization (Tortlab phase_phase).
%   [STRENGTH,PREFERRED_PHASE,DIFFERENCE] = PHASE_PHASE_COUPLING(A,B,N,M)
%   measures |mean(exp(1i*(N*A-M*B)))| on finite paired observations.
%   N and M are strictly positive integer winding numbers; this is a
%   descriptive statistic, not evidence of mechanistic interaction.
%
%   Inputs: A,B phase vectors (radians); N,M positive integer ratios.
%   Outputs: STRENGTH scalar in [0,1]; PREFERRED_PHASE radians;
%   DIFFERENCE wrapped samplewise generalized phase difference.
%
%   Example:
%       t = linspace(0,20*pi,1000)';
%       [r, phi] = phase_phase_coupling(t, 2*t + 0.3, 2, 1);
%       % r is approximately 1 for 2:1 phase locking.
%
%   Reference: tortlab/phase_phase, phase_phase_core.m.
%
    if nargin < 3 || isempty(n), n = 1; end
    if nargin < 4 || isempty(m), m = 1; end

    validateattributes(phase_a, {'numeric'}, {'vector','real','nonempty'});
    validateattributes(phase_b, {'numeric'}, {'vector','real','nonempty'});
    validateattributes(n, {'numeric'}, {'scalar','integer','positive','finite'});
    validateattributes(m, {'numeric'}, {'scalar','integer','positive','finite'});

    assert(numel(phase_a) == numel(phase_b), 'Phase vectors must match.');
    a = double(phase_a(:));
    b = double(phase_b(:));
    valid = isfinite(a) & isfinite(b);
    assert(nnz(valid) >= 2, 'At least two finite paired phases are required.');

    phase_difference = nan(size(a));
    phase_difference(valid) = angle(exp(1i * (n * a(valid) - m * b(valid))));
    z = mean(exp(1i * phase_difference(valid)));
    strength = abs(z);
    preferred_phase = angle(z);
end

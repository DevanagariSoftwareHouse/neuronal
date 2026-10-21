function [plv, phase_centers, counts] = phase_binned_plv(phase_a, phase_b, reference_phase, nbins, min_count)
%PHASE_BINNED_PLV PLV conditioned on the phase of a slower oscillation.
%   [PLV,CENTERS,COUNTS] = PHASE_BINNED_PLV(A,B,REF,NBINS,MIN_COUNT)
%   reports PLV between fast phases A and B in reference phase bins.
%   Bins with fewer than MIN_COUNT observations return NaN.
%
%   Inputs: A,B fast instantaneous phase (radians); REF slow phase;
%   NBINS positive integer >=3 (default 18); MIN_COUNT >=2 (default 5).
%   Outputs: PLV and COUNTS vectors, one entry per bin; CENTERS radians.
%
%   Example:
%       t = (0:4999)'/500;
%       slow = 2*pi*6*t;
%       fast1 = 2*pi*50*t;
%       fast2 = fast1 + 0.5*cos(slow);
%       [plv, centers] = phase_binned_plv(fast1,fast2,slow,18,10);
%
%   Related work: tortlab/Phase-Locking-Value---Modulation-Index.
%   This function returns bin-wise PLV, not the paper's modulation index.
%
    if nargin < 4 || isempty(nbins), nbins = 18; end
    if nargin < 5 || isempty(min_count), min_count = 5; end

    validateattributes(nbins, {'numeric'}, {'scalar','integer','>=',3});
    validateattributes(min_count, {'numeric'}, {'scalar','integer','>=',2});
    assert(isvector(phase_a) && isvector(phase_b) && isvector(reference_phase), ...
        'Inputs must be vectors.');
    assert(numel(phase_a) == numel(phase_b) && numel(phase_a) == numel(reference_phase), ...
        'All three phase vectors must have equal length.');

    a = double(phase_a(:));
    b = double(phase_b(:));
    r = double(reference_phase(:));
    valid = isfinite(a) & isfinite(b) & isfinite(r);
    edges = linspace(-pi, pi, nbins + 1);
    phase_centers = (edges(1:end-1) + edges(2:end))' / 2;
    reference = mod(r(valid) + pi, 2*pi) - pi;
    index = discretize(reference, edges);
    delta = a(valid) - b(valid);

    plv = nan(nbins, 1);
    counts = accumarray(index, 1, [nbins,1], @sum, 0);
    for k = 1:nbins
        if counts(k) >= min_count
            plv(k) = abs(mean(exp(1i * delta(index == k))));
        end
    end
end

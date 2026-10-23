function [valid, margin_samples, energy_outside] = filter_edge_mask(impulse, n_samples, tolerance)
%FILTER_EDGE_MASK Conservative edge exclusion from a centered kernel.
%   [VALID,MARGIN,TAIL] = filter_edge_mask(IMPULSE,N_SAMPLES,TOL)
%   IMPULSE is a finite, centered (zero lag in central sample) kernel.
%   N_SAMPLES is the signal length. TOL defaults to 1e-3.
%   MARGIN is the smallest symmetric radius whose excluded kernel tails
%   carry at most TOL of total squared kernel energy. VALID excludes
%   that radius at both ends. This is an ENERGY-BASED HEURISTIC, not a
%   rigorous upper bound on edge error or a filter-specific filtfilt mask.
%
%   Example:
%       r = filter_response(fir1(100, [4 12]/250),1,500,4096,true);
%       [valid,margin] = filter_edge_mask(r.impulse,5000,1e-3);
%
%   See also FILTER_RESPONSE.
    if nargin < 3 || isempty(tolerance), tolerance = 1e-3; end
    validateattributes(impulse, {'numeric'}, ...
        {'vector','finite','nonempty'});
    validateattributes(n_samples, {'numeric'}, ...
        {'scalar','integer','positive'});
    validateattributes(tolerance, {'numeric'}, ...
        {'scalar','real','finite','>',0,'<',1});
    h = impulse(:);
    assert(mod(numel(h),2)==1, 'Provide an odd-length centered kernel');
    e = abs(h).^2;
    total = sum(e);
    assert(total > 0, 'Kernel energy must be positive');
    radius = (numel(h)-1)/2;
    margin_samples = radius;
    for k = 0:radius
        lo = radius+1-k;
        hi = radius+1+k;
        outside = (total-sum(e(lo:hi)))/total;
        if outside <= tolerance
            margin_samples = k;
            break
        end
    end
    lo = radius+1-margin_samples;
    hi = radius+1+margin_samples;
    energy_outside = max(0,(total-sum(e(lo:hi)))/total);
    valid = false(n_samples,1);
    if 2*margin_samples < n_samples
        valid(margin_samples+1:n_samples-margin_samples) = true;
    end
end

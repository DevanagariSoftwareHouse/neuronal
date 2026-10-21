function entropy_value = spectral_entropy(power)
%SPECTRAL_ENTROPY Shannon entropy of a nonnegative PSD, normalized 0..1.
% Requires comparable frequency bins; does not measure physiological complexity.
%
%   SYNTAX
%     entropy_value = spectral_entropy(power)
%
%   INPUTS
%     power: >=2 finite nonnegative PSD bins with positive sum; comparable bin widths assumed.
%
%   OUTPUTS
%     entropy_value: Scalar normalized Shannon entropy in [0,1].
%
%   EXAMPLE
%     h_uniform = spectral_entropy(ones(8,1));
%     h_single = spectral_entropy([1;zeros(7,1)]);
%     % Uniform power gives 1; one occupied bin gives 0.
%
p=double(power(:));
assert(all(isfinite(p)) && all(p>=0) && numel(p)>=2, ...
    'PSD must have at least two finite nonnegative bins');
assert(sum(p)>0,'PSD has zero total power');
p=p/sum(p); p=p(p>0);
entropy_value=-sum(p.*log(p))/log(numel(power));
end

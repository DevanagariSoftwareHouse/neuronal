function value = phase_locking_value(phase_a,phase_b)
%PHASE_LOCKING_VALUE Resultant magnitude of phase differences, [0,1].
% Lachaux et al. (1999). Does not remove common-reference effects.
%
%   SYNTAX
%     value = phase_locking_value(phase_a,phase_b)
%
%   INPUTS
%     phase_a: Numeric phase vector in radians.
%     phase_b: Matching phase vector in radians; >=2 finite matched pairs required.
%
%   OUTPUTS
%     value: Scalar phase-difference resultant magnitude in [0,1].
%
%   EXAMPLE
%     a = linspace(-pi,pi,100)'; b = a+0.4;
%     value = phase_locking_value(a,b);
%     % A fixed phase difference gives PLV=1 even across many phase cycles.
%
a=double(phase_a(:)); b=double(phase_b(:));
assert(numel(a)==numel(b),'Phase vectors must match');
valid=isfinite(a)&isfinite(b);
assert(nnz(valid)>=2,'At least two matched samples required');
value=abs(mean(exp(1i*(a(valid)-b(valid)))));
end

function result = field_potential_inverse_tikhonov(leadfield,potentials,lambda)
%FIELD_POTENTIAL_INVERSE_TIKHONOV Ridge-regularized inverse lead-field map.
% Pesaran et al. (2018): the inverse problem is nonunique/ill-posed.
% Needs physically specified leadfield, noise model, regularization and checks.
%
%   SYNTAX
%     result = field_potential_inverse_tikhonov(leadfield,potentials,lambda)
%
%   INPUTS
%     leadfield: Finite electrodes-by-sources matrix.
%     potentials: Finite electrodes-by-samples observations.
%     lambda: Finite positive scalar ridge penalty in the units of leadfield'*leadfield.
%
%   OUTPUTS
%     result: Struct with sources (sources-by-samples), prediction/residual
%       (electrodes-by-samples), lambda and note.
%
%   EXAMPLE
%     G = [1 0.2;0.3 1;0.5 0.5]; y = G*randn(2,100);
%     result = field_potential_inverse_tikhonov(G,y,0.1);
%     % Regularization selects an estimate; it does not make sources unique.
%
g=double(leadfield); y=double(potentials);
assert(ismatrix(g) && ismatrix(y) && size(g,1)==size(y,1));
assert(all(isfinite(g(:))) && all(isfinite(y(:))));
assert(isscalar(lambda) && isfinite(lambda) && lambda>0);
n=size(g,2);
x=(g'*g+lambda*eye(n))\(g'*y);
result.sources=x;
result.prediction=g*x;
result.residual=y-result.prediction;
result.lambda=lambda;
result.note='A regularized estimate, never a unique physiological source';
end

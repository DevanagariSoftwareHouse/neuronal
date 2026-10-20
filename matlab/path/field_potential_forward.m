function potentials = field_potential_forward(leadfield,sources)
%FIELD_POTENTIAL_FORWARD Apply supplied linear lead field to source currents.
% Pesaran et al. (2018). No lead-field construction or biophysics inferred.
% leadfield=electrodes x source locations, sources=locations x samples.
%
%   SYNTAX
%     potentials = field_potential_forward(leadfield,sources)
%
%   INPUTS
%     leadfield: Finite electrodes-by-sources linear forward matrix; caller defines physical
%       units.
%     sources: Finite sources-by-samples current matrix compatible with leadfield.
%
%   OUTPUTS
%     potentials: Electrodes-by-samples matrix equal to leadfield*sources.
%
%   EXAMPLE
%     G = [1 0.2;0.3 1;0.5 0.5]; sources = randn(2,100);
%     potentials = field_potential_forward(G,sources);
%     % G is a toy mixing matrix, not an anatomical head model.
%
g=double(leadfield); s=double(sources);
assert(ismatrix(g) && ismatrix(s) && size(g,2)==size(s,1));
assert(all(isfinite(g(:))) && all(isfinite(s(:))));
potentials=g*s;
end

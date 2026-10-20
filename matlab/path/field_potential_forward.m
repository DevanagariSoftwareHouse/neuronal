function potentials = field_potential_forward(leadfield,sources)
%FIELD_POTENTIAL_FORWARD Apply supplied linear lead field to source currents.
% Pesaran et al. (2018). No lead-field construction or biophysics inferred.
% leadfield=electrodes x source locations, sources=locations x samples.
%
%   SIGNATURE DESCRIPTION
%     leadfield — the leadfield value; expected shape, units, and constraints are stated in the notes above.
%     sources — the sources value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     potentials — the returned potentials; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     potentials = field_potential_forward(leadfield, sources);
%
g=double(leadfield); s=double(sources);
assert(ismatrix(g) && ismatrix(s) && size(g,2)==size(s,1));
assert(all(isfinite(g(:))) && all(isfinite(s(:))));
potentials=g*s;
end

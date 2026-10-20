function csd = current_source_density(potential,spacing_m,conductivity)
%CURRENT_SOURCE_DENSITY Finite-difference laminar CSD (interior contacts).
% Pettersen et al. (2006) describes advanced inverse methods not used here.
% Assumes equal channel spacing, 1D laminar geometry and homogeneous sigma.
%
%   SYNTAX
%     csd = current_source_density(potential,spacing_m,conductivity)
%
%   INPUTS
%     potential: Depth-ordered channels-by-samples potentials, at least 3 channels; use volts
%       for SI output.
%     spacing_m: Positive equal intercontact spacing in metres.
%     conductivity: Positive homogeneous conductivity in S/m; default 1.
%
%   OUTPUTS
%     csd: Same-sized matrix; interior -conductivity*d2V/dz2 (A/m^3 for SI inputs), NaN at
%       outer contacts.
%
%   EXAMPLE
%     z = (0:4)'*100e-6; potential = repmat(z.^2,1,20);
%     csd = current_source_density(potential,100e-6,0.3);
%     % Outer contacts are NaN because no boundary derivative is estimated.
%
if nargin<3 || isempty(conductivity), conductivity=1; end
assert(ismatrix(potential) && size(potential,1)>=3, ...
    'Rows must be at least 3 depth-ordered channels');
assert(spacing_m>0 && conductivity>0,'Need physical spacing and conductivity');
x=double(potential);
csd=nan(size(x));
csd(2:end-1,:)=-conductivity*(x(3:end,:)- ...
    2*x(2:end-1,:)+x(1:end-2,:))/spacing_m^2;
end

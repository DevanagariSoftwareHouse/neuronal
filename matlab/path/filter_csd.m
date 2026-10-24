function [csd,depth] = filter_csd(voltage,depth_m,conductivity)
%FILTER_CSD One-dimensional finite-difference current-source density.
% [CSD,Z] = filter_csd(V,DEPTH_M,CONDUCTIVITY)
% V: samples-by-contacts in VOLTS, sorted depths in METERS, conductivity S/m.
% CSD=-conductivity*d2V/dz2 in A/m^3 at interior contacts (no edge invention).
% Supports unequal spacing; assumes homogeneous conductivity and a laminar
% one-dimensional geometry. This is NOT inverse CSD or kernel CSD.
% Example: [c,z]=filter_csd(v, (0:15)*100e-6, .3);
validateattributes(voltage,{'numeric'},{'2d','real','finite','nonempty'});
validateattributes(depth_m,{'numeric'},{'vector','real','finite','numel',size(voltage,2)});
validateattributes(conductivity,{'numeric'},{'scalar','real','finite','positive'});
z=double(depth_m(:)'); assert(numel(z)>=3 && all(diff(z)>0),'Need >=3 increasing contact depths');
v=double(voltage); h=diff(z);
slope=bsxfun(@rdivide,diff(v,1,2),h);
csd=-conductivity*bsxfun(@rdivide,2*diff(slope,1,2),h(1:end-1)+h(2:end));
depth=z(2:end-1);
end

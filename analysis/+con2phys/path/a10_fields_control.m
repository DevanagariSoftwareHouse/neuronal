%% Real median reference plus an explicit synthetic geometry control.
% No physical spacing, voltage units or conductivity are asserted for CON2PHYS.
r=struct('mode','real median reference + synthetic biophysics');
[r.referenced,r.common]=common_median_reference(c.lfp{1}');
z=(0:7)'*100e-6; t=(0:499)/c.fs;
sources=[sin(2*pi*8*t);cos(2*pi*12*t)];
leadfield=[exp(-((z-200e-6)/200e-6).^2),exp(-((z-500e-6)/200e-6).^2)];
r.potential=field_potential_forward(leadfield,sources);
r.inverse=field_potential_inverse_tikhonov(leadfield,r.potential,.01);
[r.bipolar,r.depth]=bipolar_reference_lfp(r.potential,z);
r.csd=current_source_density(r.potential,100e-6,.3);
r.assumption='Synthetic volts, meters, 0.3 S/m; NOT calibrated CON2PHYS CSD.';

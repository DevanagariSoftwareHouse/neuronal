function [phase, amplitude, analytic] = analytic_phase(signal)
%ANALYTIC_PHASE Hilbert analytic signal, phase (rad), amplitude (input units).
% Bruns (2004). Apply a scientifically justified bandpass beforehand.
%
%   SIGNATURE DESCRIPTION
%     signal — sampled signal; units and sample axis are given in the notes above.
%   RETURNS
%     phase — instantaneous phase in radians.
%     amplitude — analytic-signal amplitude in the input units.
%     analytic — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [phase, amplitude, analytic] = analytic_phase(signal);
%
validateattributes(signal,{'numeric'},{'vector','real','finite','nonempty'});
analytic=hilbert(double(signal));
amplitude=abs(analytic);
phase=angle(analytic);
end

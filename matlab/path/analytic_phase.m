function [phase, amplitude, analytic] = analytic_phase(signal)
%ANALYTIC_PHASE Hilbert analytic signal, phase (rad), amplitude (input units).
% Bruns (2004). Apply a scientifically justified bandpass beforehand.
%
%   SYNTAX
%     [phase, amplitude, analytic] = analytic_phase(signal)
%
%   INPUTS
%     signal: Finite real nonempty vector, normally already bandpass filtered.
%
%   OUTPUTS
%     phase: Instantaneous phase in radians, same shape as signal.
%     amplitude: Nonnegative envelope in signal units, same shape.
%     analytic: Complex Hilbert analytic signal, same shape.
%
%   Requires Signal Processing Toolbox (hilbert).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     [phase, amplitude, analytic] = analytic_phase(x);
%     % Interpret phase away from edges and for a justified narrow band.
%
validateattributes(signal,{'numeric'},{'vector','real','finite','nonempty'});
analytic=hilbert(double(signal));
amplitude=abs(analytic);
phase=angle(analytic);
end

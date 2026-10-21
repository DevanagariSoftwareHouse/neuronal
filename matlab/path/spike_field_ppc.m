function [ppc,spike_phase] = spike_field_ppc(lfp,spike_times,srate,edge_seconds)
%SPIKE_FIELD_PPC Spike-LFP pairwise phase consistency at spike timestamps.
% Vinck et al. (2010); requires PRE-FILTERED narrow-band LFP input.
%
%   SYNTAX
%     [ppc,spike_phase] = spike_field_ppc(lfp,spike_times,srate,edge_seconds)
%
%   INPUTS
%     lfp: Finite prefiltered narrow-band real LFP vector.
%     spike_times: Finite spike timestamps in seconds, first LFP sample at time zero.
%     srate: Positive sampling rate in Hz.
%     edge_seconds: Nonnegative margin excluded at each recording end; default 2.
%
%   OUTPUTS
%     ppc: Scalar pairwise phase consistency; NaN if fewer than 2 usable spike phases.
%     spike_phase: Column of retained phases in radians after complex interpolation;
%       zero-amplitude/invalid samples removed.
%
%   Requires Signal Processing Toolbox (hilbert).
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs; lfp = sin(2*pi*8*t);
%     [ppc, spike_phase] = spike_field_ppc(lfp,(2.1:0.125:7.9)',fs,2);
%     % Use phase estimates away from filtering/Hilbert edges.
%
if nargin<4 || isempty(edge_seconds), edge_seconds=2; end
x=double(lfp(:)); t=double(spike_times(:));
assert(all(isfinite(x)) && all(isfinite(t)) && srate>0);
stop=numel(x)/srate;
t=t(t>=edge_seconds & t<stop-edge_seconds);
analytic=hilbert(x);
sample_t=(0:numel(x)-1)'/srate;
z=interp1(sample_t,analytic,t,'linear');
z=z(isfinite(z)&abs(z)>0);
spike_phase=angle(z);
ppc=pairwise_phase_consistency(spike_phase);
end

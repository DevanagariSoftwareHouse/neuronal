function [ppc,spike_phase] = spike_field_ppc(lfp,spike_times,srate,edge_seconds)
%SPIKE_FIELD_PPC Spike-LFP pairwise phase consistency at spike timestamps.
% Vinck et al. (2010); requires PRE-FILTERED narrow-band LFP input.
%
%   SIGNATURE DESCRIPTION
%     lfp — the lfp value; expected shape, units, and constraints are stated in the notes above.
%     spike_times — spike/event timestamps in seconds.
%     srate — sampling rate in Hz.
%     edge_seconds — the edge seconds value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     ppc — pairwise phase consistency estimate.
%     spike_phase — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [ppc, spike_phase] = spike_field_ppc(lfp, spike_times, srate, edge_seconds);
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

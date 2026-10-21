function [mi,amplitude_by_phase,edges] = modulation_index(phase,amplitude,nbins)
%MODULATION_INDEX Tort et al. (2010) phase-amplitude modulation index.
% Inputs are low-frequency phase (rad) and high-frequency envelope.
% This is descriptive: use surrogates and control waveform non-sinusoidality.
%
%   SYNTAX
%     [mi,amplitude_by_phase,edges] = modulation_index(phase,amplitude,nbins)
%
%   INPUTS
%     phase: Low-frequency phase vector in radians, wrapped internally to [-pi,pi).
%     amplitude: Matching nonnegative high-frequency envelope; invalid pairs are removed.
%     nbins: Integer phase bins >=3; default 18; at least 2*nbins valid observations required.
%
%   OUTPUTS
%     mi: Scalar normalized KL modulation index; NaN for empty phase bins or zero total
%       amplitude.
%     amplitude_by_phase: nbins-by-1 mean envelope per phase bin.
%     edges: 1-by-(nbins+1) phase-bin edges in radians.
%
%   EXAMPLE
%     phase = linspace(-pi,pi,1001)'; amplitude = 1+0.5*cos(phase);
%     [mi, amplitude_by_phase, edges] = modulation_index(phase,amplitude,18);
%     % A descriptive toy modulation; surrogate controls are a separate step.
%
if nargin<3 || isempty(nbins), nbins=18; end
phase=double(phase(:)); amplitude=double(amplitude(:));
assert(numel(phase)==numel(amplitude),'Phase and amplitude must match');
assert(nbins>=3 && nbins==floor(nbins),'nbins must be integer >= 3');
valid=isfinite(phase)&isfinite(amplitude)&amplitude>=0;
phase=mod(phase(valid)+pi,2*pi)-pi; amplitude=amplitude(valid);
edges=linspace(-pi,pi,nbins+1);
assert(numel(phase)>=2*nbins,'Insufficient observations');
index=discretize(phase,edges);
amplitude_by_phase=nan(nbins,1);
for k=1:nbins
    values=amplitude(index==k);
    if ~isempty(values), amplitude_by_phase(k)=mean(values); end
end
if any(~isfinite(amplitude_by_phase)) || sum(amplitude_by_phase)==0
    mi=NaN; return
end
prob=amplitude_by_phase/sum(amplitude_by_phase);
prob=prob(prob>0);
mi=(log(nbins)+sum(prob.*log(prob)))/log(nbins);
end

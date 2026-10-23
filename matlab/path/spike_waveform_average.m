function [template,sem] = spike_waveform_average(waveforms)
%SPIKE_WAVEFORM_AVERAGE Mean +/- SEM of aligned waveform snippets.
% Input spikes x channels x samples; outputs channels x samples.
%
%   SYNTAX
%     [template,sem] = spike_waveform_average(waveforms)
%
%   INPUTS
%     waveforms: Finite numeric spikes-by-channels-by-samples tensor with >=2 spikes and >1
%       waveform sample.
%
%   OUTPUTS
%     template: Channels-by-samples mean waveform.
%     sem: Channels-by-samples sample SD divided by sqrt(number of spikes), in waveform units.
%
%   EXAMPLE
%     rng(7); waves = randn(20,2,61);
%     [template, sem] = spike_waveform_average(waves);
%     % Both outputs are 2-by-61, including when only one channel is supplied.
%
assert(isnumeric(waveforms) && ndims(waveforms)==3 && size(waveforms,1)>=2);
assert(all(isfinite(waveforms(:))));
template=reshape(mean(double(waveforms),1),size(waveforms,2),size(waveforms,3));
sem=reshape(std(double(waveforms),0,1),size(waveforms,2),size(waveforms,3))/sqrt(size(waveforms,1));
end

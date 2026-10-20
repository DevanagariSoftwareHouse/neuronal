function [template,sem] = spike_waveform_average(waveforms)
%SPIKE_WAVEFORM_AVERAGE Mean +/- SEM of aligned waveform snippets.
% Input spikes x channels x samples; outputs channels x samples.
%
%   SIGNATURE DESCRIPTION
%     waveforms — the waveforms value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     template — the returned value; see the summary above for meaning and units.
%     sem — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [template, sem] = spike_waveform_average(waveforms);
%
assert(isnumeric(waveforms) && ndims(waveforms)==3 && size(waveforms,1)>=2);
assert(all(isfinite(waveforms(:))));
template=reshape(mean(double(waveforms),1),size(waveforms,2),size(waveforms,3));
sem=reshape(std(double(waveforms),0,1),size(waveforms,2),size(waveforms,3))/sqrt(size(waveforms,1));
end

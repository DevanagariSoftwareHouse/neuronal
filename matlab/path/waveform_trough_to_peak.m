function width_ms = waveform_trough_to_peak(waveform,srate)
%WAVEFORM_TROUGH_TO_PEAK Trough to subsequent maximum time in ms.
% Used for extracellular waveform classification, not definitive cell identity.
% Input is one averaged waveform; use waveform sampling rate (often 30000 Hz).
%
%   SYNTAX
%     width_ms = waveform_trough_to_peak(waveform,srate)
%
%   INPUTS
%     waveform: Nonempty finite real averaged waveform vector.
%     srate: Positive waveform sampling rate in Hz (often 30000).
%
%   OUTPUTS
%     width_ms: Scalar milliseconds from global trough to subsequent maximum; NaN if trough is
%       the last sample. The subsequent maximum need not be positive.
%
%   EXAMPLE
%     waveform = [0 -1 -3 -1 0.5 1 0];
%     width_ms = waveform_trough_to_peak(waveform,30000);
%     % Three samples from trough to peak correspond to 0.1 ms.
%
validateattributes(waveform,{'numeric'},{'vector','real','finite','nonempty'});
assert(srate>0,'Sample rate must be positive');
w=double(waveform(:));
[~,trough]=min(w);
if trough==numel(w), width_ms=NaN; return; end
[~,peak_rel]=max(w(trough+1:end));
width_ms=1000*peak_rel/srate;
end

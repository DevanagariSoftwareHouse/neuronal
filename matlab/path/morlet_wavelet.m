function [coefficient, time] = morlet_wavelet(signal,srate,frequency_hz,cycles)
%MORLET_WAVELET Complex Morlet convolution at one central frequency.
% Time resolution varies with cycles/frequency; output is complex-valued.
%
%   SIGNATURE DESCRIPTION
%     signal — sampled signal; units and sample axis are given in the notes above.
%     srate — sampling rate in Hz.
%     frequency_hz — frequency in Hz.
%     cycles — the cycles value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     coefficient — the returned value; see the summary above for meaning and units.
%     time — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [coefficient, time] = morlet_wavelet(signal, srate, frequency_hz, cycles);
%
if nargin<4 || isempty(cycles), cycles=6; end
validateattributes(signal,{'numeric'},{'vector','real','finite','nonempty'});
assert(srate>0 && frequency_hz>0 && frequency_hz<srate/2 && cycles>=3, ...
    'Invalid sampling rate, frequency or cycles');
sigma=cycles/(2*pi*frequency_hz);
t=(-ceil(3.5*sigma*srate):ceil(3.5*sigma*srate))'/srate;
kernel=(exp(1i*2*pi*frequency_hz*t)-exp(-cycles^2/2)) ...
    .*exp(-t.^2/(2*sigma^2));
kernel=kernel/sqrt(sum(abs(kernel).^2));
coefficient=conv(double(signal(:)),kernel,'same');
time=(0:numel(signal)-1)'/srate;
end

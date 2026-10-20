function [coefficient, time] = morlet_wavelet(signal,srate,frequency_hz,cycles)
%MORLET_WAVELET Complex Morlet convolution at one central frequency.
% Time resolution varies with cycles/frequency; output is complex-valued.
%
%   SYNTAX
%     [coefficient, time] = morlet_wavelet(signal,srate,frequency_hz,cycles)
%
%   INPUTS
%     signal: Nonempty finite real vector.
%     srate: Positive sampling rate in Hz.
%     frequency_hz: Central frequency strictly inside (0,srate/2).
%     cycles: Wavelet width in cycles, >=3; default 6.
%
%   OUTPUTS
%     coefficient: Samples-by-1 complex convolution with a unit-energy Morlet kernel.
%     time: Samples-by-1 timestamps in seconds, beginning at zero.
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     [coefficient, time] = morlet_wavelet(x,fs,8,6);
%     power = abs(coefficient).^2;
%     % Unit-energy coefficients are not a PSD in units squared/Hz.
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

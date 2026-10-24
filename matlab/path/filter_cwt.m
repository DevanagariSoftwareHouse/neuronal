function [coefficient,frequency,coi] = filter_cwt(x,fs,wavelet,varargin)
%FILTER_CWT Analytic CWT for one channel using the Wavelet Toolbox backend.
% [C,F,COI] = filter_cwt(X,FS,WAVELET,...) forwards name/value options to CWT.
% WAVELET: 'morse', 'amor', or 'bump'. X is one vector, C frequency-by-time.
% F and COI are Hz (sampling frequency supplied). C is complex, not PSD.
% Requires Wavelet Toolbox. CWT does not include an independent DC band.
% Example: [c,f,coi]=filter_cwt(randn(5000,1),500,'morse');
filter_require('cwt');
validateattributes(x,{'numeric'},{'vector','real','finite','nonempty'});
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
wavelet=validatestring(wavelet,{'morse','amor','bump'});
[coefficient,frequency,coi]=cwt(double(x(:)),wavelet,fs,varargin{:});
end

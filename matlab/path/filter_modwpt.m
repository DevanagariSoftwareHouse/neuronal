function [coefficient,meta] = filter_modwpt(x,fs,level,wavelet)
%FILTER_MODWPT Full-rate terminal wavelet packet coefficients for one channel.
% [C,M] = filter_modwpt(X,FS,LEVEL,WAVELET); C is packets-by-samples.
% M contains backend frequency centers in Hz, levels and packet energies.
% Coefficients are not reconstructed time-aligned voltage contributions.
% Uses CPU double input for R2019a. Requires Wavelet Toolbox.
% Example: [c,m]=filter_modwpt(randn(4096,1),500,4,'db4');
filter_require('modwpt');
validateattributes(x,{'numeric'},{'vector','real','finite','nonempty'});
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(level,{'numeric'},{'scalar','integer','positive','<=',floor(log2(numel(x)))});
assert(numel(x)*2^level<=2e7,'Output too large; use shorter records or lower level');
[coefficient,lev,f,e]=modwpt(double(x(:)),wavelet,level);
meta=struct('fs',fs,'level',lev,'frequency_hz',f*fs,'energy',e, ...
    'wavelet',wavelet,'representation','modwpt_coefficients');
end

function [details,meta] = filter_modwpt_details(x,fs,level,wavelet)
%FILTER_MODWPT_DETAILS Reconstructed terminal packet contributions.
% [D,M] = filter_modwpt_details(X,FS,LEVEL,WAVELET)
% D: packets-by-samples. SUM(D,1) reconstructs X up to roundoff.
% Nominal band edges are approximate; boundaries follow MODWPTDETAILS.
% Example: [d,m]=filter_modwpt_details(randn(4096,1),500,4,'db4');
filter_require('modwptdetails');
validateattributes(x,{'numeric'},{'vector','real','finite','nonempty'});
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(level,{'numeric'},{'scalar','integer','positive','<=',floor(log2(numel(x)))});
assert(numel(x)*2^level<=2e7,'Output too large');
details=modwptdetails(double(x(:)),wavelet,level);
edges=(0:2^level)'*fs/(2*2^level);
meta=struct('fs',fs,'level',level,'wavelet',wavelet, ...
    'nominal_edges_hz',[edges(1:end-1) edges(2:end)], ...
    'representation','modwpt_details');
end

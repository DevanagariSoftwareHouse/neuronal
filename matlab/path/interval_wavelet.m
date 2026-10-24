function node = interval_wavelet(N, fs, support, scale_s, translation_s)
%INTERVAL_WAVELET Generate the affine support interval of a wavelet atom.
% node = interval_wavelet(N, fs, support, scale_s, translation_s)
% support=[a b] is dimensionless, scale_s>0; bounds are translation_s +
% scale_s*[a b]. Returns empty if outside the session. For infinite-support
% wavelets choose an explicit truncation support; this is NOT a transform.
% Example: w = interval_wavelet(1000,500,[-3 3],.1,1);

validateattributes(support, {'numeric'}, {'vector','numel',2,'real','finite'});
assert(support(2)>support(1), 'interval:Bounds', 'Support must have positive width.');
validateattributes(scale_s, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(translation_s, {'numeric'}, {'scalar','real','finite'});
node = interval_from_bounds(N,fs,double(translation_s)+double(scale_s)*double(support(:).'));
end

function [y,noise,coefficients] = filter_line_regression(x,fs,frequencies)
%FILTER_LINE_REGRESSION Remove fitted sinusoids at specified line frequencies.
% [Y,NOISE,B] = filter_line_regression(X,FS,FREQUENCIES)
% Joint least squares with an intercept; only sine/cosine terms are removed.
% X: samples-by-channels or vector. Frequencies must be distinct, inside
% (0,Nyquist). Stationary amplitude/phase are assumed over the entire call.
% Example: y=filter_line_regression(x,500,[60 120 180]);
[x,row]=filter_input(x);
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(frequencies,{'numeric'},{'vector','real','finite','positive','<',fs/2});
f=double(frequencies(:)'); assert(numel(unique(f))==numel(f),'Duplicate frequencies');
t=(0:size(x,1)-1)'/fs;
a=2*pi*t*f; basis=[ones(size(t)) cos(a) sin(a)];
assert(size(basis,1)>size(basis,2) && rank(basis)==size(basis,2), ...
    'Not enough independent samples to estimate these sinusoids');
coefficients=basis\x;
noise=basis(:,2:end)*coefficients(2:end,:); y=x-noise;
if row, y=y.'; noise=noise.'; end
end

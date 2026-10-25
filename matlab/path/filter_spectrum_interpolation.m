function [y,mask] = filter_spectrum_interpolation(x,fs,bands)
%FILTER_SPECTRUM_INTERPOLATION Replace contaminated FFT magnitudes.
% [Y,MASK] = filter_spectrum_interpolation(X,FS,BANDS); BANDS is K-by-2 Hz.
% Linearly interpolates positive-bin magnitudes between clean neighbors,
% retaining original phases and restoring Hermitian symmetry. DC/Nyquist
% cannot be replaced. Adjacent/overlapping masks are handled jointly.
% Whole-record, periodic FFT boundary assumption; not a causal filter.
% This is a defined magnitude-interpolation variant, not an exact replica
% of every setting in Leske & Dalal (2019).
% Example: y=filter_spectrum_interpolation(x,500,[59 61;119 121]);
[x,row]=filter_input(x);
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(bands,{'numeric'},{'2d','real','finite','nonempty','positive','<',fs/2});
assert(size(bands,2)==2 && all(bands(:,1)<bands(:,2)),'Expected low/high rows');
n=size(x,1); nf=floor(n/2)+1; f=(0:nf-1)'*fs/n;
mask=false(nf,1);
for k=1:size(bands,1), mask=mask | (f>=bands(k,1) & f<=bands(k,2)); end
assert(~mask(1) && ~mask(end),'Contamination must have clean bracketing bins');
z=fft(x,[],1); a=abs(z(1:nf,:));
if any(mask)
    a(mask,:)=interp1(f(~mask),a(~mask,:),f(mask),'linear');
    z(1:nf,:)=a.*exp(1i*angle(z(1:nf,:)));
end
if mod(n,2)==0, z(nf+1:end,:)=conj(z(nf-1:-1:2,:));
else, z(nf+1:end,:)=conj(z(nf:-1:2,:)); end
y=real(ifft(z,[],1));
if row, y=y.'; end
end

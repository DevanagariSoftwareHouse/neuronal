function [s,f,t] = filter_stft(x,fs,window_samples,overlap,nfft)
%FILTER_STFT Complex short-time Fourier coefficients, not filtered voltage.
% [S,F,T] = filter_stft(X,FS,WINDOW_SAMPLES,OVERLAP,NFFT)
% S: frequencies-by-windows-by-channels, raw FFT of Hann-windowed segments.
% F is Hz, T is window-center seconds; no PSD normalization is implied.
% Only complete windows are used. OVERLAP in [0,1), rounded to samples.
% Example: [s,f,t]=filter_stft(randn(5000,2),500,500,.5,512);
[x,~]=filter_input(x);
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(window_samples,{'numeric'},{'scalar','integer','>=',2,'<=',size(x,1)});
validateattributes(overlap,{'numeric'},{'scalar','real','finite','>=',0,'<',1});
validateattributes(nfft,{'numeric'},{'scalar','integer','>=',window_samples});
hop=max(1,round(window_samples*(1-overlap)));
starts=1:hop:size(x,1)-window_samples+1;
nf=floor(nfft/2)+1;
assert(double(nf)*numel(starts)*size(x,2)<=2e7,'Output too large; process fewer channels/windows');
s=complex(zeros(nf,numel(starts),size(x,2)));
w=.5-.5*cos(2*pi*(0:window_samples-1)'/window_samples);
for j=1:numel(starts)
    z=fft(bsxfun(@times,x(starts(j)+(0:window_samples-1),:),w),nfft,1);
    s(:,j,:)=reshape(z(1:nf,:),nf,1,size(x,2));
end
f=(0:nf-1)'*fs/nfft; t=(starts-1+(window_samples-1)/2)'/fs;
end

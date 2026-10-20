function y = multivariate_phase_surrogate(x)
%MULTIVARIATE_PHASE_SURROGATE Shared random Fourier phase across channels.
% Samples in rows, channels in columns. Preserves cross-spectral matrices
% at each Fourier bin. Prichard & Theiler (1994); stationary signals only.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%   RETURNS
%     y — the returned y; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     y = multivariate_phase_surrogate(x);
%
assert(isnumeric(x)&&isreal(x)&&ismatrix(x)&&all(isfinite(x(:))));
[n,~]=size(x); assert(n>=4);
f=fft(double(x),[],1);
idx=2:floor((n+1)/2);
phi=exp(1i*2*pi*rand(numel(idx),1));
f(idx,:)=bsxfun(@times,f(idx,:),phi);
f(n-idx+2,:)=conj(f(idx,:));
y=real(ifft(f,[],1));
end

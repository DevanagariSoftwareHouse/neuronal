function [y,diagnostics] = iaaft_surrogate(x,max_iter,tolerance)
%IAAFT_SURROGATE Iterative amplitude adjusted Fourier transform surrogate.
% Preserves empirical marginal exactly (up to permutation); matches Fourier
% amplitudes approximately. Schreiber & Schmitz (1996).
% Nonconvergence and residual spectral error MUST be inspected.
if nargin<2||isempty(max_iter), max_iter=1000; end
if nargin<3||isempty(tolerance), tolerance=1e-8; end
assert(isvector(x)&&isreal(x)&&all(isfinite(x(:)))&&numel(x)>=8);
assert(max_iter>=1&&tolerance>=0);
row=isrow(x); x=double(x(:)); n=numel(x);
sorted=sort(x); target=abs(fft(x));
y=x(randperm(n)); previous=inf; error_history=zeros(max_iter,1);
for k=1:max_iter
    f=fft(y);
    f=target.*exp(1i*angle(f));
    z=real(ifft(f));
    [~,order]=sort(z);
    y(order)=sorted;
    err=norm(abs(fft(y))-target)/max(norm(target),eps);
    error_history(k)=err;
    if abs(previous-err)<=tolerance, break; end
    previous=err;
end
diagnostics=struct('iterations',k,'relative_spectral_error',err, ...
    'converged',k<max_iter,'error_history',error_history(1:k));
if row, y=y.'; end
end

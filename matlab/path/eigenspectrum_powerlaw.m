function fit = eigenspectrum_powerlaw(eigenvalues,ranks)
%EIGENSPECTRUM_POWERLAW Log-log rank-eigenvalue exponent.
% Stringer et al. (2019), doi:10.1038/s41586-019-1346-5.
%
%   SYNTAX
%     fit = eigenspectrum_powerlaw(eigenvalues,ranks)
%
%   INPUTS
%     eigenvalues: At least 3 finite nonnegative values in descending order.
%     ranks: Integer indices to fit; default all ranks; at least 3 selected eigenvalues must be
%       positive.
%
%   OUTPUTS
%     fit: Struct: exponent, natural-log intercept, retained ranks and r_squared.
%
%   EXAMPLE
%     v = (1:20)'.^(-1.5);
%     fit = eigenspectrum_powerlaw(v,2:15);
%     % Ideal data recover exponent 1.5.
%
v=double(eigenvalues(:));
assert(numel(v)>=3 && all(isfinite(v)) && all(v>=0));
assert(all(diff(v)<=0),'Descending eigenvalues required');
if nargin<2 || isempty(ranks), ranks=(1:numel(v))'; end
ranks=double(ranks(:));
assert(all(ranks>=1 & ranks<=numel(v) & ranks==floor(ranks)));
ranks=ranks(v(ranks)>0);
assert(numel(ranks)>=3,'Need three positive spectral values');
p=polyfit(log(ranks),log(v(ranks)),1);
residual=log(v(ranks))-polyval(p,log(ranks));
fit.exponent=-p(1);
fit.intercept=p(2);
fit.ranks=ranks;
denom=sum((log(v(ranks))-mean(log(v(ranks)))).^2);
fit.r_squared=1-sum(residual.^2)/max(denom,eps);
end

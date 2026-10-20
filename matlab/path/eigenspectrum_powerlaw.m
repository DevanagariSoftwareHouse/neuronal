function fit = eigenspectrum_powerlaw(eigenvalues,ranks)
%EIGENSPECTRUM_POWERLAW Log-log rank-eigenvalue exponent.
% Stringer et al. (2019), doi:10.1038/s41586-019-1346-5.
%
%   SIGNATURE DESCRIPTION
%     eigenvalues — the eigenvalues value; expected shape, units, and constraints are stated in the notes above.
%     ranks — the ranks value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     fit — the returned fit; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     fit = eigenspectrum_powerlaw(eigenvalues, ranks);
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

function result = granger_causality(activity,source,target,lags)
%GRANGER_CAUSALITY Conditional multivariate autoregressive Granger score.
% Barnett & Seth (2014); Dhamala et al. (2008) use related spectral methods.
% Rows=time bins, cols=variables. Score=log(var_reduced/var_full).
% Predictive dependence is NOT physical causality. Validate model residuals.
%
%   SIGNATURE DESCRIPTION
%     activity — neural activity matrix; observation/time rows and unit columns unless noted.
%     source — the source value; expected shape, units, and constraints are stated in the notes above.
%     target — the target value; expected shape, units, and constraints are stated in the notes above.
%     lags — lag indices in samples or bins, according to the function notes.
%   RETURNS
%     result — result structure containing the estimates and diagnostics described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     result = granger_causality(activity, source, target, lags);
%
x=double(activity); [n,p]=size(x);
assert(all(isfinite(x(:))) && p>=2 && source~=target && ...
    source>=1 && source<=p && target>=1 && target<=p);
assert(lags>=1 && lags==floor(lags) && n-lags>p*lags+3, ...
    'Insufficient observations for the requested VAR order');
lagged=zeros(n-lags,p*lags);
for k=1:lags
    lagged(:,(k-1)*p+(1:p))=x(lags+1-k:n-k,:);
end
response=x(lags+1:end,target);
full=[ones(n-lags,1),lagged];
excluded=source+(0:lags-1)*p;
keep=true(1,size(full,2)); keep(1+excluded)=false;
reduced=full(:,keep);
e_full=response-full*(full\response);
e_reduced=response-reduced*(reduced\response);
v_full=mean(e_full.^2); v_reduced=mean(e_reduced.^2);
result.log_variance_ratio=log(v_reduced/v_full);
result.full_variance=v_full; result.reduced_variance=v_reduced;
result.samples=n-lags; result.lags=lags; result.source=source;
result.target=target;
end

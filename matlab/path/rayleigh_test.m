function result = rayleigh_test(angles)
%RAYLEIGH_TEST Rayleigh's test against circular uniformity.
% Berens (2009), CircStat, DOI 10.18637/jss.v031.i10.
% Formula assumes independent circular samples, unimodal alternative.
% Small n and strongly dependent LFP samples require additional care.
%
%   SIGNATURE DESCRIPTION
%     angles — the angles value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     result — result structure containing the estimates and diagnostics described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     result = rayleigh_test(angles);
%
a=double(angles(:));
assert(numel(a)>=5 && all(isfinite(a)) && isreal(a));
n=numel(a);
R=abs(sum(exp(1i*a)));
r=R/n;
z=n*r^2;
% Large-sample analytic approximation used by CircStat; bounded for roundoff.
p=exp(sqrt(max(0,1+4*n+4*(n^2-R^2)))-(1+2*n));
result.p_value=min(1,max(0,p));
result.z=z;
result.resultant_length=r;
result.n=n;
result.mean_direction=circular_mean(a);
result.note='Not appropriate for dependent samples or multimodal alternatives';
end

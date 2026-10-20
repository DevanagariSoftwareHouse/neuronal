function y = aaft_surrogate(x)
%AAFT_SURROGATE Amplitude-adjusted FT surrogate (approximate spectrum).
% Rank-map original data to Gaussian, randomize phase, map ranks back.
% Theiler et al. (1992). Prefer IAAFT when spectral fidelity matters.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%   RETURNS
%     y — the returned y; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     y = aaft_surrogate(x);
%
assert(isvector(x)&&isreal(x)&&all(isfinite(x(:)))&&numel(x)>=8);
row=isrow(x); x=double(x(:)); n=numel(x);
[~,order]=sort(x); g=sort(randn(n,1));
gauss=zeros(n,1); gauss(order)=g;
z=phase_randomized_surrogate(gauss);
[~,order]=sort(z); y=zeros(n,1); y(order)=sort(x);
if row, y=y.'; end
end

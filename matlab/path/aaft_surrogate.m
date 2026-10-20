function y = aaft_surrogate(x)
%AAFT_SURROGATE Amplitude-adjusted FT surrogate (approximate spectrum).
% Rank-map original data to Gaussian, randomize phase, map ranks back.
% Theiler et al. (1992). Prefer IAAFT when spectral fidelity matters.
%
%   SYNTAX
%     y = aaft_surrogate(x)
%
%   INPUTS
%     x: Finite real vector with at least 8 samples.
%
%   OUTPUTS
%     y: Surrogate with the same shape and sorted values as x.
%
%   EXAMPLE
%     rng(7); x = randn(1000,1);
%     y = aaft_surrogate(x);
%     % Compare spectra as well as the preserved amplitude distribution.
%
assert(isvector(x)&&isreal(x)&&all(isfinite(x(:)))&&numel(x)>=8);
row=isrow(x); x=double(x(:)); n=numel(x);
[~,order]=sort(x); g=sort(randn(n,1));
gauss=zeros(n,1); gauss(order)=g;
z=phase_randomized_surrogate(gauss);
[~,order]=sort(z); y=zeros(n,1); y(order)=sort(x);
if row, y=y.'; end
end

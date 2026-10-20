function [band,critical] = simultaneous_confidence_band(theta,boot,level)
%SIMULTANEOUS_CONFIDENCE_BAND Draft max-t bootstrap band.
% theta: 1 x frequencies; boot: B x frequencies from JOINT resampling.
% Assumes centered bootstrap distribution approximates estimation errors.
%
%   SYNTAX
%     [band,critical] = simultaneous_confidence_band(theta,boot,level)
%
%   INPUTS
%     theta: Finite vector of original jointly estimated statistics.
%     boot: Finite B-by-features joint bootstrap replicates, B>=20; every column must vary.
%     level: Simultaneous confidence probability in (0,1); default 0.95.
%
%   OUTPUTS
%     band: 2-by-features lower/upper max-t bounds.
%     critical: Scalar quantile of maximum standardized deviations.
%
%   EXAMPLE
%     rng(7); x = randn(40,5); theta = mean(x,1); boot = zeros(500,5);
%     for k = 1:500, boot(k,:) = mean(x(randi(40,40,1),:),1); end
%     [band, critical] = simultaneous_confidence_band(theta,boot,0.95);
%     % Resample the same rows jointly for all features.
%
if nargin<3||isempty(level), level=.95; end
theta=reshape(theta,1,[]);
assert(isnumeric(boot)&&ismatrix(boot)&&size(boot,2)==numel(theta));
assert(size(boot,1)>=20&&all(isfinite(boot(:)))&&all(isfinite(theta)));
assert(level>0&&level<1);
se=std(boot,0,1);
assert(all(se>0),'Zero-variance coordinates cannot be studentized.');
maxstat=max(abs((boot-theta)./se),[],2);
critical=quantile(maxstat,level);
band=[theta-critical*se;theta+critical*se];
end

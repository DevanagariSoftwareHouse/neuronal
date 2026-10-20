function [band,critical] = simultaneous_confidence_band(theta,boot,level)
%SIMULTANEOUS_CONFIDENCE_BAND Draft max-t bootstrap band.
% theta: 1 x frequencies; boot: B x frequencies from JOINT resampling.
% Assumes centered bootstrap distribution approximates estimation errors.
%
%   SIGNATURE DESCRIPTION
%     theta — the theta value; expected shape, units, and constraints are stated in the notes above.
%     boot — the boot value; expected shape, units, and constraints are stated in the notes above.
%     level — confidence level between 0 and 1.
%   RETURNS
%     band — the returned value; see the summary above for meaning and units.
%     critical — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [band, critical] = simultaneous_confidence_band(theta, boot, level);
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

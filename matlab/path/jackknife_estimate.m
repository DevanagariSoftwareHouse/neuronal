function out = jackknife_estimate(x,statfun)
%JACKKNIFE_ESTIMATE Delete-one-row jackknife for vector-valued statistics.
% Rows must be independent experimental units, not time samples of an LFP.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%     statfun — function handle that computes the requested statistic.
%   RETURNS
%     out — the returned out; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     out = jackknife_estimate(x, statfun);
%
if nargin<2||isempty(statfun), statfun=@(a)mean(a,1); end
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))));
n=size(x,1); assert(n>=3);
theta=reshape(statfun(x),1,[]);
leave=zeros(n,numel(theta));
for i=1:n
    keep=true(n,1); keep(i)=false;
    v=reshape(statfun(x(keep,:)),1,[]);
    assert(numel(v)==numel(theta)&&all(isfinite(v)));
    leave(i,:)=v;
end
m=mean(leave,1);
se=sqrt((n-1)/n*sum((leave-m).^2,1));
out=struct('estimate',theta,'leave_one_out',leave, ...
    'bias',(n-1)*(m-theta),'se',se,'bias_corrected',n*theta-(n-1)*m);
end

function out = jackknife_estimate(x,statfun)
%JACKKNIFE_ESTIMATE Delete-one-row jackknife for vector-valued statistics.
% Rows must be independent experimental units, not time samples of an LFP.
%
%   SYNTAX
%     out = jackknife_estimate(x,statfun)
%
%   INPUTS
%     x: Finite independent-observations-by-features matrix, at least 3 rows.
%     statfun: Function returning a fixed-size finite statistic; default column means.
%
%   OUTPUTS
%     out: Struct: estimate, bias, se, bias_corrected (1-by-P) and leave_one_out
%       (observations-by-P).
%
%   EXAMPLE
%     x = [1;2;4;5;7];
%     out = jackknife_estimate(x,@mean);
%     % out.leave_one_out shows the influence of each omitted observation.
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

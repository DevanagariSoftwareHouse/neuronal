function out = delete_group_jackknife(x,group,statfun)
%DELETE_GROUP_JACKKNIFE Leave-one-group-out sensitivity estimates.
% Equal-weight jackknife SE is appropriate only for comparable groups.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%     group — group identifier for each observation.
%     statfun — function handle that computes the requested statistic.
%   RETURNS
%     out — the returned out; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     out = delete_group_jackknife(x, group, statfun);
%
if nargin<3||isempty(statfun), statfun=@(z)mean(z,1); end
assert(size(x,1)==numel(group)&&all(isfinite(x(:))));
[groups,~,id]=unique(group(:),'stable'); g=numel(groups);
assert(g>=3); theta=reshape(statfun(x),1,[]);
leave=zeros(g,numel(theta));
for j=1:g
    leave(j,:)=reshape(statfun(x(id~=j,:)),1,[]);
end
mu=mean(leave,1);
out=struct('estimate',theta,'leave_group_out',leave,'groups',groups, ...
    'range',[min(leave,[],1);max(leave,[],1)], ...
    'se_equal_group',sqrt((g-1)/g*sum((leave-mu).^2,1)));
end

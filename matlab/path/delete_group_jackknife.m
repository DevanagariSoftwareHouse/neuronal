function out = delete_group_jackknife(x,group,statfun)
%DELETE_GROUP_JACKKNIFE Leave-one-group-out sensitivity estimates.
% Equal-weight jackknife SE is appropriate only for comparable groups.
%
%   SYNTAX
%     out = delete_group_jackknife(x,group,statfun)
%
%   INPUTS
%     x: Finite observations-by-features matrix.
%     group: One group label per row, with at least 3 distinct groups.
%     statfun: Function returning a fixed-size statistic; default column means.
%
%   OUTPUTS
%     out: Struct: estimate (1-by-P), leave_group_out (groups-by-P), groups, range (2-by-P),
%       se_equal_group (1-by-P).
%
%   EXAMPLE
%     x = (1:12)'; group = repelem((1:4)',3);
%     out = delete_group_jackknife(x,group,@mean);
%     % Compare leave_group_out to identify influential groups.
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

function out = sensitivity_analysis(configs,evaluatefun)
%SENSITIVITY_ANALYSIS Evaluate statistic across caller-specified settings.
% configs is a cell array; evaluatefun(config) returns numeric row vector.
%
%   SIGNATURE DESCRIPTION
%     configs — the configs value; expected shape, units, and constraints are stated in the notes above.
%     evaluatefun — the evaluatefun value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     out — the returned out; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     out = sensitivity_analysis(configs, evaluatefun);
%
assert(iscell(configs)&&~isempty(configs));
first=reshape(evaluatefun(configs{1}),1,[]);
values=zeros(numel(configs),numel(first)); values(1,:)=first;
for j=2:numel(configs)
    v=reshape(evaluatefun(configs{j}),1,[]);
    assert(numel(v)==numel(first)&&all(isfinite(v)));
    values(j,:)=v;
end
out=struct('configurations',{configs},'values',values, ...
    'range',[min(values,[],1);max(values,[],1)], ...
    'mean',mean(values,1));
end

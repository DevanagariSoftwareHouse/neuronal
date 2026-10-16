function out = sensitivity_analysis(configs,evaluatefun)
%SENSITIVITY_ANALYSIS Evaluate statistic across caller-specified settings.
% configs is a cell array; evaluatefun(config) returns numeric row vector.
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

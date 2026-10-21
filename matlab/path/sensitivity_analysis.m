function out = sensitivity_analysis(configs,evaluatefun)
%SENSITIVITY_ANALYSIS Evaluate statistic across caller-specified settings.
% configs is a cell array; evaluatefun(config) returns numeric row vector.
%
%   SYNTAX
%     out = sensitivity_analysis(configs,evaluatefun)
%
%   INPUTS
%     configs: Nonempty cell array of caller-defined configurations.
%     evaluatefun: Function accepting one configuration and returning a fixed-size finite
%       numeric statistic.
%
%   OUTPUTS
%     out: Struct with configurations, values (configurations-by-P), range (2-by-P min/max) and
%       mean (1-by-P).
%
%   EXAMPLE
%     x = [1;2;3;8;9]; configs = {3,5,10};
%     out = sensitivity_analysis(configs,@(cutoff) mean(x(x<=cutoff)));
%     % The range describes setting sensitivity, not a confidence interval.
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

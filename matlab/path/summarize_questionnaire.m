function out = summarize_questionnaire(values,labels,units,description,cfg,axis,statfun)
%SUMMARIZE_QUESTIONNAIRE Method-aware marginal intervals; no winner selection.
% values: one observations-by-features numeric matrix per group.
% axis: unit/trial/time_block. statfun defaults to arithmetic mean.
% Missing ordered rows are rejected: deleting them changes temporal adjacency.
if nargin<7, statfun=@mean; is_mean=true; else, is_mean=false; end
n=numel(values); estimate=nan(n,1); bounds=nan(n,2); retained=zeros(n,1);
inference=cell(n,1);
for k=1:n
    x=double(values{k});
    if isvector(x), x=x(:); end
    good=all(isfinite(x),2);
    if strcmp(axis,'unit'), x=x(good,:);
    else
        assert(all(good),'questionnaire:MissingOrderedRows', ...
            'Ordered observations contain missing values. Define contiguous valid segments before inference.');
    end
    retained(k)=size(x,1);
    local=cfg; local.current_group=k;
    inference{k}=questionnaire_ci(x,statfun,local,axis,is_mean);
    estimate(k)=inference{k}.estimate; bounds(k,:)=inference{k}.ci;
end
out=struct('summary',table(labels(:),estimate,bounds(:,1),bounds(:,2),retained, ...
    'VariableNames',{'group','mean','ci_low','ci_high','n'}), ...
    'units',units,'method',description,'config',cfg,'inference',{inference}, ...
    'answer','Descriptive estimates; paired contrasts required to select a winner.');
end

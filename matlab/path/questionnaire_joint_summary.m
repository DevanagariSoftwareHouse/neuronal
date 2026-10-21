function out = questionnaire_joint_summary(x,statistics,labels,units,description,cfg,axis,mean_values)
%QUESTIONNAIRE_JOINT_SUMMARY Shared rows and RNG seed preserve group pairing.
% statistics is a cell of scalar @(x) functions applied to the SAME matrix.
% IID/block/balanced resamplers therefore use identical indices in each group.
% Callbacks for weighted/parametric/hierarchical methods must be group-specific.
if nargin<8, mean_values=[]; end
if ~isempty(mean_values), assert(isequal(size(mean_values),[size(x,1),numel(statistics)])); end
n=numel(statistics); point=nan(n,1); bounds=nan(n,2); inference=cell(n,1);
for k=1:n
    local=cfg; local.current_group=k;
    if ~isempty(mean_values), local.current_mean_values=mean_values(:,k); end
    inference{k}=questionnaire_ci(x,statistics{k},local,axis,~isempty(mean_values));
    point(k)=inference{k}.estimate; bounds(k,:)=inference{k}.ci;
end
out=struct('summary',table(labels(:),point,bounds(:,1),bounds(:,2), ...
    'VariableNames',{'group','mean','ci_low','ci_high'}), ...
    'inference',{inference},'config',cfg,'units',units,'method',description, ...
    'answer','Paired contrasts and across-animal inference remain required.', ...
    'resampling_rows',x,'pairing','Common observation row IDs; identical resampling plans for supported empirical methods.');
out=questionnaire_decide(out,true);
end

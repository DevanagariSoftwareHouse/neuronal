function out = questionnaire_joint_summary(x,statistics,labels,units,description,cfg,axis)
%QUESTIONNAIRE_JOINT_SUMMARY Shared rows and RNG seed preserve group pairing.
% statistics is a cell of scalar @(x) functions applied to the SAME matrix.
% IID/block/balanced resamplers therefore use identical indices in each group.
% Callbacks for weighted/parametric/hierarchical methods must be group-specific.
n=numel(statistics); point=nan(n,1); bounds=nan(n,2); inference=cell(n,1);
for k=1:n
    local=cfg; local.current_group=k;
    inference{k}=questionnaire_ci(x,statistics{k},local,axis,false);
    point(k)=inference{k}.estimate; bounds(k,:)=inference{k}.ci;
end
out=struct('summary',table(labels(:),point,bounds(:,1),bounds(:,2), ...
    'VariableNames',{'group','mean','ci_low','ci_high'}), ...
    'inference',{inference},'config',cfg,'units',units,'method',description, ...
    'answer','Paired contrasts and across-animal inference remain required.', ...
    'resampling_rows',x,'pairing','Common observation rows; shared resampling seed.');
end

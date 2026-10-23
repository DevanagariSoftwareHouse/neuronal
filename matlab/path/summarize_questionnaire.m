function out = summarize_questionnaire(values,labels,units,description,cfg,axis,statfun)
%SUMMARIZE_QUESTIONNAIRE Method-aware intervals with guarded within-recording decisions.
% values: one observations-by-features numeric matrix per group.
% axis: unit/trial/time_block. statfun defaults to arithmetic mean.
% Ordered means resample common row IDs, retaining missing positions.
if nargin<7, statfun=@mean; is_mean=true; else, is_mean=false; end
n=numel(values);
if ~strcmp(axis,'unit') && is_mean
    lengths=cellfun(@numel,values);
    assert(all(lengths==lengths(1)),'questionnaire:Pairing','Ordered groups must share a row grid.');
    grid=nan(lengths(1),n); statistics=cell(n,1);
    minimum=3;
    if isfield(cfg,'minimum_finite_rows'), minimum=cfg.minimum_finite_rows; end
    validateattributes(minimum,{'numeric'},{'scalar','integer','>=',3});
    for k=1:n
        grid(:,k)=values{k}(:); column=grid(:,k);
        if sum(isfinite(column))<minimum
            statistics{k}=@(ids)NaN;
        else
            statistics{k}=@(ids)questionnaire_nanmean(ids,column,minimum);
        end
    end
    out=questionnaire_joint_summary((1:lengths(1))',statistics,labels,units,description,cfg,axis,grid);
    out.observation_grid=grid;
    out.summary.n_finite=sum(isfinite(grid),1)';
    out.minimum_finite_rows=minimum;
    return
end
estimate=nan(n,1); bounds=nan(n,2); retained=zeros(n,1);
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
    local.seed=cfg.seed+k-1; % independent streams, not accidental row pairing
    inference{k}=questionnaire_ci(x,statfun,local,axis,is_mean);
    estimate(k)=inference{k}.estimate; bounds(k,:)=inference{k}.ci;
end
out=struct('summary',table(labels(:),estimate,bounds(:,1),bounds(:,2),retained, ...
    'VariableNames',{'group','mean','ci_low','ci_high','n'}), ...
    'units',units,'method',description,'config',cfg,'inference',{inference}, ...
    'answer','Descriptive estimates; paired contrasts required to select a winner.');
out.pairing='independent group streams; independence requires explicit justification';
out=questionnaire_decide(out,false);
end

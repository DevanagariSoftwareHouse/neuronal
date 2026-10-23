function [t,labels,valid] = trial_times(data,cfg)
%TRIAL_TIMES Explicit trial-column mapping; never guess dataset semantics.
% cfg.trial_columns (or data.trial_columns): struct with trial_start,
% stim_start, outcome, trial_end, A, C; values are column indices in data.trial.
% t is trials x 4 in seconds; labels is trials x 2 [A C].
columns=cfg.trial_columns;
if isempty(columns)&&isfield(data,'trial_columns'), columns=data.trial_columns; end
names={'trial_start','stim_start','outcome','trial_end','A','C'};
assert(isstruct(columns)&&all(isfield(columns,names)), ...
    'questionnaire:TrialColumns','Supply trial_columns: trial_start, stim_start, outcome, trial_end, A, C.');
assert(isfield(data,'trial')&&isnumeric(data.trial));
idx=cellfun(@(s)columns.(s),names);
validateattributes(idx,{'numeric'},{'vector','integer','positive','<=',size(data.trial,2)});
assert(numel(unique(idx))==6,'Trial columns must be distinct.');
t=double(data.trial(:,idx(1:4))); labels=double(data.trial(:,idx(5:6)));
valid=all(isfinite(t),2)&all(diff(t,1,2)>0,2)&t(:,1)>=0 & ...
    t(:,4)<=size(data.lfp_1,2)/double(data.srate);
end

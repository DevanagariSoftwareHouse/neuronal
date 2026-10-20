function results = run_questionnaire(data,qcfg,outputFile)
%RUN_QUESTIONNAIRE Execute q01:q15 and export questionarie.tex plus MAT evidence.
% DATA is one raw recording (see RESAMPLING.md). QCFG configures resampling.
% OUTPUTFILE defaults to analysis/results/questionnaire/questionarie.tex.
% Each failure is recorded and printed; no stale answer is reused. This does
% not aggregate animals or interpret marginal CIs as comparative tests.
questionnaire_root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(questionnaire_root,'analysis'));
addpath(fullfile(questionnaire_root,'matlab','path'));
if nargin<2 || isempty(qcfg), qcfg=struct(); end
if nargin<3 || isempty(outputFile)
    outputFile=fullfile(questionnaire_root,'analysis','results','questionnaire','questionarie.tex');
end
questionnaire_output=char(outputFile);
questionnaire_specification=questionnaire_spec();
results=struct();
results.meta=struct('generated_at',datestr(now,30),'matlab_version',version, ...
    'scope','one recording; no automatic population-level winner', ...
    'requested_config',qcfg,'revision',getenv('GITHUB_SHA'));
if isfield(qcfg,'report_revision'), results.meta.revision=qcfg.report_revision; end
if isfield(data,'source'), results.meta.source=data.source; end
questionnaire_rng=rng;
questionnaire_cleanup=onCleanup(@()rng(questionnaire_rng)); %#ok<NASGU>
for questionnaire_index=1:numel(questionnaire_specification)
    questionnaire_item=questionnaire_specification(questionnaire_index);
    try
        eval(['con2phys.' questionnaire_item.script]);
        questionnaire_value=eval(questionnaire_item.id);
        results.(questionnaire_item.id)=struct('status','completed','result',questionnaire_value);
    catch questionnaire_error
        results.(questionnaire_item.id)=struct('status','failed', ...
            'identifier',questionnaire_error.identifier,'message',questionnaire_error.message, ...
            'stack',questionnaire_error.stack);
        warning('questionnaire:QuestionFailed','%s failed: %s', ...
            questionnaire_item.id,questionnaire_error.message);
    end
end
questionnaire_parent=fileparts(questionnaire_output);
if ~isempty(questionnaire_parent)&&~exist(questionnaire_parent,'dir'), mkdir(questionnaire_parent); end
[questionnaire_parent,questionnaire_name]=fileparts(questionnaire_output);
save(fullfile(questionnaire_parent,[questionnaire_name '.mat']),'results','-v7.3');
write_questionnaire_tex(results,questionnaire_output);
fprintf('Questionnaire report: %s\n',questionnaire_output);
end

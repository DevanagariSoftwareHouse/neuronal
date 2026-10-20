function test_questionnaire_report()
%TEST_QUESTIONNAIRE_REPORT Verify completeness, escaping and partial results.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'matlab','path'));
spec=questionnaire_spec(); assert(numel(spec)==15);
filename=[tempname '.tex']; cleanup=onCleanup(@()delete(filename)); %#ok<NASGU>
write_questionnaire_tex(struct(),filename);
s=fileread(filename);
for k=1:15, assert(contains(s,[upper(spec(k).id) '. '])); end
assert(contains(s,'Not executed.') && ~contains(s,'NaN'));
cfg=struct('bootstrap',40,'seed',42,'current_question','q01', ...
    'inference',struct('method','bayesian','level',.9));
r=summarize_questionnaire({(1:10)',(2:11)',(3:12)'}, ...
    {'Area 1';'Area 2';'Area 3'},'Hz','synthetic test',cfg,'unit');
results=struct('q01',struct('status','completed','result',r), ...
    'q02',struct('status','failed','message','missing_field & 50%'), ...
    'meta',struct('source','synthetic_only'));
write_questionnaire_tex(results,filename); s=fileread(filename);
assert(contains(s,'90.0 percent credible interval'));
assert(contains(s,'5.5') && contains(s,'missing\_field \& 50\%'));
assert(contains(s,'Execution failure.') && contains(s,'synthetic\_only'));
fprintf('Questionnaire TeX report tests passed.\n');
end

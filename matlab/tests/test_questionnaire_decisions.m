function test_questionnaire_decisions()
%TEST_QUESTIONNAIRE_DECISIONS Paired covariance, multiplicity and missing grid.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'matlab','path'));
cfg=struct('bootstrap',400,'seed',12,'current_question','q02', ...
    'inference',struct('method','stationary','block_length',4));
z=sin((1:100)'); x=[z z+10 z+20];
s={@(a)mean(a(:,1)),@(a)mean(a(:,2)),@(a)mean(a(:,3))};
r=questionnaire_joint_summary(x,s,{'a';'b';'c'},'x','test',cfg,'time_block');
assert(r.decision.winner==3);
assert(all(r.decision.contrasts.p_holm<.05));
assert(max(abs(r.decision.contrasts.simultaneous_low-[-10;-20;-10]))<1e-9);
r=questionnaire_joint_summary([z z z],s,{'a';'b';'c'},'x','test',cfg,'time_block');
assert(isempty(r.decision.winner)&&all(r.decision.contrasts.p_holm==1));
cfg.current_question='q01'; cfg.inference=struct('method','percentile');
r=summarize_questionnaire({z,z+10,z+20},{'a';'b';'c'},'Hz','test',cfg,'unit');
assert(isempty(r.decision.winner)); % No implicit independence declaration.
cfg.independent_groups=true;
r=summarize_questionnaire({z,z+10,z+20},{'a';'b';'c'},'Hz','test',cfg,'unit');
assert(r.decision.winner==1); % Q01 minimizes.
cfg.current_question='q02'; cfg.inference=struct('method','stationary');
v=z; v([3 40 85])=NaN;
r=summarize_questionnaire({v,z+10,z+20},{'a';'b';'c'},'x','test',cfg,'time_block');
assert(isequal(r.resampling_rows,(1:100)'));
assert(isequaln(r.observation_grid(:,1),v));
assert(r.summary.n_finite(1)==97 && abs(r.summary.mean(1)-mean(v,'omitnan'))<1e-12);
% A sparse observed mean can be estimable while some resamples are not.
cfg.inference=struct('method','percentile','allow_iid',true);
r=summarize_questionnaire({[1;2;3;NaN;NaN;NaN],(1:6)',(2:7)'}, ...
    {'a';'b';'c'},'x','test',cfg,'trial');
assert(isnan(r.summary.ci_low(1)) && contains(r.inference{1}.status,'replicate'));
assert(isfinite(r.summary.mean(1)) && isempty(r.decision.winner));
fprintf('Questionnaire contrast and missing-grid regressions passed.\n');
end

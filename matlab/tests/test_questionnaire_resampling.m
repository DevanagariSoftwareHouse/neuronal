function test_questionnaire_resampling()
%TEST_QUESTIONNAIRE_RESAMPLING Dispatch, dependency guards and q01:q15 smoke.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root,'matlab','path')); addpath(fullfile(root,'analysis'));
cfg=struct('bootstrap',40,'seed',72,'current_question','q01','inference',struct());
x=(1:20)';
methods={'percentile','basic','bca','balanced','bayesian','studentized', ...
    'block','stationary','hierarchical','parametric','wild','subsampling','jackknife'};
for test_i=1:numel(methods)
    cfg.inference=struct('method',methods{test_i},'level',.9);
    if strcmp(methods{test_i},'hierarchical')
        cfg.inference.groups={x(1:10),x(11:20)};
        cfg.inference.group_statfun=@(g)mean(cellfun(@mean,g));
    elseif strcmp(methods{test_i},'parametric')
        cfg.inference.fitfun=@(z)[mean(z),std(z)];
        cfg.inference.simulatefun=@(p,n)p(1)+p(2)*randn(n,1);
    end
    before=rng;
    result=questionnaire_ci(x,@mean,cfg,'unit',true);
    assert(isequal(rng,before),'Global RNG leaked.');
    assert(abs(result.estimate-10.5)<1e-10 && result.ci(1)<=result.ci(2));
    again=questionnaire_ci(x,@mean,cfg,'unit',true);
    assert(isequal(result.ci,again.ci));
end
cfg.inference=struct('method','percentile');
expect_error(@()questionnaire_ci(x,@mean,cfg,'trial',true),'questionnaire:Dependence');
cfg.inference=struct('method','bayesian');
expect_error(@()questionnaire_ci(x,@median,cfg,'unit',false),'questionnaire:Callback');
cfg.inference=struct('method','auto');
r=questionnaire_ci(x,@mean,cfg,'time_block',true);
assert(strcmp(r.method,'stationary'));
cfg.questions.q01=struct('method','balanced');
r=questionnaire_ci(x,@mean,cfg,'unit',true); assert(strcmp(r.method,'balanced'));
% A whole-block ordering property: >=9 of 11 transitions are contiguous.
[~,~,draws]=block_bootstrap_ci((1:12)',@(z)mean(mod(diff(z),12)==1),4,40,.95,7,false);
assert(all(draws>=9/11-1e-12),'Fixed blocks were interleaved.');
% Shared rows must yield identical replicates for identical statistics.
cfg=rmfield(cfg,'questions'); cfg.inference=struct('method','stationary');
j=questionnaire_joint_summary(x,{@mean,@mean},{'a';'b'},'test','test',cfg,'trial');
assert(isequal(j.inference{1}.draws,j.inference{2}.draws));
expect_error(@()summarize_questionnaire({[1;NaN;3]},{'a'},'x','x',cfg,'trial'), ...
    'questionnaire:MissingOrderedRows');
run_questions();
fprintf('Questionnaire method dispatch and q01:q15 synthetic smoke passed.\n');
end
function expect_error(f,id)
try
    f();
catch err
    assert(strcmp(err.identifier,id),'Unexpected error: %s',err.message); return
end
error('Expected error %s was not raised.',id);
end
function run_questions()
% Synthetic fixture is a recording, not claimed to reproduce biological data.
rng(18,'twister'); fs=500; duration=150; units=12;
data=struct('srate',fs,'lfp_1',randn(3,fs*duration), ...
    'lfp_2',randn(3,fs*duration),'lfp_3',randn(3,fs*duration));
data.waveform_cluster=(1:units)'; data.waveform_area=repelem((1:3)',4);
data.waveform=zeros(units,64); data.spike_timestamp=[]; data.spike_cluster=[];
for unit=1:units
    peak=30+10*mod(unit,2); samples=1:64;
    data.waveform(unit,:)=-exp(-(samples-20).^2/8)+.6*exp(-(samples-peak).^2/8);
    times=sort(duration*rand(1800,1));
    data.spike_timestamp=[data.spike_timestamp;times]; %#ok<AGROW>
    data.spike_cluster=[data.spike_cluster;repmat(unit,numel(times),1)]; %#ok<AGROW>
end
start=(2:3:134)'; n=numel(start);
data.trial=[start start+.3 start+.8 start+1.3 mod((1:n)',2) mod((0:n-1)',3)+1];
qcfg=struct('bootstrap',20,'null_replicates',0,'block_seconds',5,'matched_units',3, ...
    'trial_columns',struct('trial_start',1,'stim_start',2,'outcome',3,'trial_end',4,'A',5,'C',6));
files=dir(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
    'analysis','+con2phys','q*.m'));
for test_question=1:numel(files)
    [~,name]=fileparts(files(test_question).name);
    if strcmp(name,'q00_prepare'), continue; end
    eval(['con2phys.' name]);
    result=eval(name(1:3));
    assert(height(result.summary)==3 && isfield(result,'inference'));
    assert(all(ismember({'ci_low','ci_high'},result.summary.Properties.VariableNames)));
end
% Full-recording counts divided by exposure, with no trial restriction.
assert(all(abs(q01.unit.rate_hz-12)<1e-10));
% The PR point estimator uses exactly the same fixed units as its replicates.
for test_area=1:3
    expected=participation_ratio(vertcat(q13.trials{test_area}{:}));
    assert(abs(expected-q13.summary.mean(test_area))<1e-10);
end
end

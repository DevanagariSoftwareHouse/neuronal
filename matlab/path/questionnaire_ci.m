function out = questionnaire_ci(x,statfun,cfg,axis,is_mean)
%QUESTIONNAIRE_CI Dispatch one scalar estimand to matlab/path resampling.
% x: observations in rows; axis: 'unit', 'trial', or 'time_block'.
% cfg.inference defines method, level, block_length (ROWS), and callbacks.
% cfg.questions.qNN overrides inference fields for that question.
% No automatic fallback between methods. Uncertainty is within recording.
if nargin<5, is_mean=false; end
opt=struct('method','auto','level',.95,'block_length',[], ...
    'sefun',[],'weighted_statfun',[],'fitfun',[],'simulatefun',[], ...
    'groups',[],'group_statfun',[],'subsample_size',[],'allow_iid',false,'group_options',{{}});
if isfield(cfg,'inference'), opt=merge_options(opt,cfg.inference); end
if isfield(cfg,'questions') && isfield(cfg.questions,cfg.current_question)
    opt=merge_options(opt,cfg.questions.(cfg.current_question));
end
if isfield(cfg,'current_group') && ~isempty(opt.group_options)
    assert(numel(opt.group_options)>=cfg.current_group,'Missing group_options entry.');
    opt=merge_options(opt,opt.group_options{cfg.current_group});
end
method=lower(char(opt.method));
if strcmp(method,'auto')
    if ismember(axis,{'time_block','trial'}), method='stationary'; else, method='percentile'; end
end
assert(isnumeric(x)&&ismatrix(x)&&all(isfinite(x(:))), ...
    'questionnaire:Nonfinite','Pass finite rows; preserve time gaps explicitly.');
B=cfg.bootstrap; seed=cfg.seed; n=size(x,1);
if n==0, theta=NaN; else, theta=statfun(x); end
assert(isscalar(theta),'questionnaire:Scalar','Statistic must be scalar.');
validateattributes(opt.level,{'numeric'},{'scalar','>',0,'<',1});
out=struct('estimate',theta,'ci',[nan nan],'draws',[], ...
    'method',method,'level',opt.level,'axis',axis,'n',n,'seed',seed, ...
    'interval_kind','confidence','scope','within-recording conditional', ...
    'status','insufficient observations','block_length',[],'draws_kind','statistic');
if strcmp(method,'bayesian'), out.interval_kind='credible'; end
if strcmp(method,'studentized'), out.draws_kind='studentized pivot'; end
known={'percentile','basic','bca','balanced','bayesian','studentized', ...
    'block','stationary','hierarchical','parametric','wild','subsampling','jackknife'};
assert(ismember(method,known),'questionnaire:Method','Unknown method: %s',method);
if ismember(axis,{'time_block','trial'}) && ...
        ~ismember(method,{'block','stationary','parametric','hierarchical'})
    assert(opt.allow_iid,'questionnaire:Dependence', ...
        'Ordered rows require block/stationary resampling, or explicit allow_iid=true.');
end
if n<3, return; end
if ~isfinite(theta), out.status='undefined point estimate'; return; end
L=opt.block_length;
if isempty(L), L=max(1,min(n-1,round(sqrt(n)))); end
validateattributes(L,{'numeric'},{'scalar','integer','>=',1,'<=',n});
% Some toolbox primitives use the global stream. Restore it even on error.
old=rng; cleanup=onCleanup(@()rng(old)); rng(seed,'twister'); %#ok<NASGU>
draws=[];
try
switch method
    case {'percentile','basic','bca'}
        [ci,theta,draws]=bootstrap_ci(x,statfun,B,opt.level,method,seed);
    case 'balanced'
        [ci,theta,draws]=balanced_bootstrap_ci(x,statfun,B,opt.level,seed);
    case 'bayesian'
        weighted=opt.weighted_statfun;
        if isempty(weighted)&&is_mean, weighted=@(a,w)sum(a.*w); end
        assert(isa(weighted,'function_handle'),'questionnaire:Callback', ...
            'Bayesian bootstrap requires weighted_statfun for this estimand.');
        [ci,theta,draws]=bayesian_bootstrap_ci(x,weighted,B,opt.level,seed);
        out.interval_kind='credible';
    case 'studentized'
        sefun=opt.sefun;
        if isempty(sefun)&&is_mean, sefun=@(a)std(a)/sqrt(size(a,1)); end
        assert(isa(sefun,'function_handle'),'questionnaire:Callback','Supply sefun.');
        [ci,theta,draws]=bootstrap_t_ci(x,statfun,sefun,B,opt.level,seed);
        out.draws_kind='studentized pivot';
    case {'block','stationary'}
        [ci,theta,draws]=block_bootstrap_ci(x,statfun,L,B,opt.level,seed,strcmp(method,'stationary'));
        out.block_length=L;
    case 'hierarchical'
        assert(iscell(opt.groups)&&isa(opt.group_statfun,'function_handle'), ...
            'questionnaire:Hierarchy','Supply independent groups and group_statfun; never infer animal IDs.');
        [ci,theta,draws]=hierarchical_bootstrap_ci(opt.groups,opt.group_statfun,B,opt.level,seed);
        out.scope='explicit supplied hierarchy'; out.n=numel(opt.groups);
    case 'parametric'
        assert(isa(opt.fitfun,'function_handle')&&isa(opt.simulatefun,'function_handle'), ...
            'questionnaire:Callback','Supply fitfun and simulatefun for the observation model.');
        [ci,theta,draws]=parametric_bootstrap_ci(x,opt.fitfun,opt.simulatefun,statfun,B,opt.level);
    case 'wild'
        assert(is_mean,'questionnaire:Estimand', ...
            'Wild OLS is supported only for a scalar mean (intercept-only model).');
        [ci,theta,draws]=wild_bootstrap_ci(ones(n,1),x,B,opt.level,seed);
    case 'subsampling'
        [ci,theta,draws]=subsampling_ci(x,statfun,opt.subsample_size,B,opt.level);
    case 'jackknife'
        [ci,j]=jackknife_ci(x,statfun,opt.level); theta=j.estimate;
        out.jackknife=j; % CI is centered on bias-corrected estimate.
end
catch err
    if strcmp(err.identifier,'questionnaire:InsufficientFiniteRows')
        out.status='interval unavailable: insufficient finite observations in a replicate';
        return
    end
    rethrow(err);
end
assert(all(isfinite(ci(:)))&&ci(1)<=ci(2),'questionnaire:InvalidInterval','Method produced an invalid interval.');
assert(isscalar(theta)&&numel(ci)==2,'questionnaire:Shape','Expected scalar estimate and two endpoints.');
% A custom weighted/hierarchical statistic must estimate the same quantity.
assert(abs(theta-out.estimate)<=1e-8*max(1,abs(out.estimate)), ...
    'questionnaire:Estimand','Callback point estimate differs from the question statistic.');
if ~isempty(draws), assert(all(isfinite(draws(:))),'questionnaire:InvalidReplicate','Nonfinite replicate; revise estimator or design.'); end
out.estimate=theta; out.ci=reshape(ci,1,2); out.draws=draws; out.status='ok';
end
function out=merge_options(out,in)
assert(isstruct(in)&&isscalar(in));
names=fieldnames(in);
for k=1:numel(names)
    assert(isfield(out,names{k}),'questionnaire:Option','Unknown inference option: %s',names{k});
    out.(names{k})=in.(names{k});
end
end

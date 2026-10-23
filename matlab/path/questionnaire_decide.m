function out = questionnaire_decide(out,paired)
%QUESTIONNAIRE_DECIDE Within-recording comparisons of three scalar endpoints.
% All three pairs form the multiplicity family before selecting an extremum.
% Reports centered-bootstrap two-sided p-values with Holm adjustment and
% Bonferroni basic CIs. A winner must pass BOTH gates against both competitors.
% Supports matching empirical resampling plans with statistic-scale draws.
% This is approximate bootstrap inference, not an exact randomization test.
cfg=out.config; qid=cfg.current_question;
decision=struct('winner',[],'choice','Not enough data / no differences', ...
    'scope','within-recording only','status','unavailable','alpha',.05, ...
    'paired',paired,'family','all three pairwise contrasts','contrasts',[]);
out.decision=decision;
out.answer='Not enough data / no differences (compatible contrast inference unavailable).';
if strcmp(qid,'q09')
    out.answer='Not enough data to identify physiological excitation/inhibition.';
    out.decision.status='waveform proxy does not identify physiological E/I'; return
end
if strcmp(qid,'q03')
    out.answer='Not enough data: candidate detections do not validate physiological sharp-wave ripples.';
    out.decision.status='candidate screen requires physiological validation'; return
end
if ~paired
    allowed=isfield(cfg,'independent_groups') && isequal(cfg.independent_groups,true);
    if ~allowed
        out.answer='Not enough data / no differences (group independence not established).';
        out.decision.status='independent_groups=true requires scientific justification'; return
    end
end
n=height(out.summary);
if n~=3, out.decision.status='decision requires three groups'; return; end
allowed={'percentile','basic','bca','balanced','block','stationary'};
first=out.inference{1}; draws=[];
for k=1:n
    infk=out.inference{k};
    if ~strcmp(infk.status,'ok') || ~ismember(infk.method,allowed) || ...
            ~strcmp(infk.draws_kind,'statistic') || ~strcmp(infk.method,first.method) || ...
            ~isequal(infk.block_length,first.block_length) || (paired && infk.n~=first.n)
        out.decision.status='requires compatible empirical statistic draws'; return
    end
    if k>1 && size(infk.draws,1)~=size(draws,1)
        out.decision.status='replicate counts differ'; return
    end
    draws(:,k)=infk.draws(:); %#ok<AGROW>
end
if any(~isfinite(draws(:)))||any(~isfinite(out.summary.mean))
    out.decision.status='nonfinite estimate or replicate'; return
end
B=size(draws,1); pairs=nchoosek(1:n,2); m=size(pairs,1); alpha=.05;
effect=zeros(m,1); lower=effect; upper=effect; raw=effect;
for j=1:m
    a=pairs(j,1); b=pairs(j,2);
    effect(j)=out.summary.mean(a)-out.summary.mean(b);
    errors=draws(:,a)-draws(:,b)-effect(j);
    q=quantile(errors,[alpha/(2*m),1-alpha/(2*m)]);
    lower(j)=effect(j)-q(2); upper(j)=effect(j)-q(1);
    raw(j)=(1+sum(abs(errors)>=abs(effect(j))))/(B+1);
end
[sorted,order]=sort(raw); adjusted=min(1,cummax((m:-1:1)'.*sorted));
holm=zeros(m,1); holm(order)=adjusted;
out.decision.contrasts=table(pairs(:,1),pairs(:,2),effect,lower,upper,raw,holm, ...
    'VariableNames',{'group_a','group_b','difference','simultaneous_low','simultaneous_high','p_bootstrap','p_holm'});
out.decision.status='computed; approximate bootstrap inference';
small=ismember(qid,{'q01','q10','q14'});
if small, [~,candidate]=min(out.summary.mean); else, [~,candidate]=max(out.summary.mean); end
wins=true;
for competitor=setdiff(1:n,candidate)
    j=find(any(pairs==candidate,2)&any(pairs==competitor,2));
    if pairs(j,1)==candidate, lo=lower(j); hi=upper(j);
    else, lo=-upper(j); hi=-lower(j); end
    if small, wins=wins && hi<0; else, wins=wins && lo>0; end
    wins=wins && holm(j)<alpha;
end
if wins
    out.decision.winner=candidate; out.decision.choice=out.summary.group{candidate};
    out.answer=[out.decision.choice ' (within-recording comparison; population inference pending).'];
else
    out.answer='Not enough data / no differences (no uniquely supported within-recording winner).';
end
end

%% Synthetic calibration: exchangeable independent groups, ordered features.
% These p-values are controls, NOT claims about dependent bins or animal areas.
r=struct('mode','synthetic inference controls'); B=cfg.draws;
a=randn(24,20); b=randn(26,20); b(:,8:12)=b(:,8:12)+1;
r.independent=permutation_test(a(:,10),b(:,10),@(x,y)mean(x)-mean(y),B,'two-sided');
r.maxstat=maxstat_permutation_test(a,b,@(x,y)mean(x,1)-mean(y,1),B,'two-sided');
r.cluster=cluster_permutation_test(a,b,2,B);
r.surrogate_max=surrogate_maxstat_test(r.maxstat.observed,r.maxstat.null,'two-sided');
r.mc=monte_carlo_null_test(a(:,1),@mean,@()randn(24,1),B,'two-sided');
% Repeated null calibration is available through sensitivity_analysis.
r.effect_sensitivity=sensitivity_analysis({0,.5,1},@(effect)mean(a(:,10))-mean(b(:,10)+effect));
assert(all(r.maxstat.p_corrected>=1/(B+1) & r.maxstat.p_corrected<=1));

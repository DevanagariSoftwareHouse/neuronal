%% Regression for paired callback arity and legacy-compatible spike plotting.
% No CON2PHYS recordings required. Run in MATLAB from repository root.
here=fileparts(mfilename('fullpath'));
root=fileparts(fileparts(here));
addpath(fullfile(root,'matlab','path'));
rng(42,'twister');
a=(1:8)'; b=a+2;
result=paired_permutation_test(a,b,@mean,39,'two-sided');
assert(result.observed==2,'Paired statistic must be mean(B-A).');
assert(isequal(size(result.null),[39 1]));
assert(result.p>=1/40 && result.p<=1);
% Exercise the actual plotting script, including its API calls.
c=struct('duration',10,'T',10,'s',(0.1:0.1:9.9)', ...
    's2',(0.15:0.1:9.95)','spikes',{{(0.1:0.1:9.9)'}});
c.C=spike_bins(c.spikes,0:.1:10);
cfg=struct('plots',true);
old_visibility=get(0,'DefaultFigureVisible');
guard=onCleanup(@()set(0,'DefaultFigureVisible',old_visibility));
set(0,'DefaultFigureVisible','off');
run(fullfile(root,'analysis','+con2phys','path','a02_spike_statistics.m'));
assert(numel(findall(gcf,'Type','axes'))==2);
close(gcf); clear guard
fprintf('CON2PHYS runtime regression checks passed.\n');

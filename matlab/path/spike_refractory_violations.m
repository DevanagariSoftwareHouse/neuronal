function out = spike_refractory_violations(times,refractory_seconds)
%SPIKE_REFRACTORY_VIOLATIONS Adjacent short-ISI proportion; not contamination.
% Hill et al. (2011); quality metric candidate, timestamps in seconds.
%
%   SYNTAX
%     out = spike_refractory_violations(times,refractory_seconds)
%
%   INPUTS
%     times: Finite spike timestamps in seconds, sorted internally.
%     refractory_seconds: Positive short-ISI threshold in seconds; default 0.002.
%
%   OUTPUTS
%     out: Struct: count (strictly shorter ISIs), intervals, fraction (NaN with <2 spikes),
%       threshold_seconds.
%
%   EXAMPLE
%     out = spike_refractory_violations([0.1 0.101 0.3],0.002);
%     % One of two adjacent intervals violates the threshold; fraction=0.5.
%
if nargin<2 || isempty(refractory_seconds), refractory_seconds=.002; end
times=double(times(:));
assert(all(isfinite(times)) && refractory_seconds>0);
isi=diff(sort(times));
out.count=sum(isi<refractory_seconds);
out.intervals=numel(isi);
out.fraction=NaN;
if ~isempty(isi), out.fraction=out.count/out.intervals; end
out.threshold_seconds=refractory_seconds;
end

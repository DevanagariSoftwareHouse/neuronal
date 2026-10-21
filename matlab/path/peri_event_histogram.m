function [centers_s,rate_hz,trial_counts] = peri_event_histogram(spike_times,event_times,edges_s)
%PERI_EVENT_HISTOGRAM Event-aligned firing rate and trial-by-bin counts.
% [CENTERS_S, RATE_HZ, TRIAL_COUNTS] = PERI_EVENT_HISTOGRAM(TIMES, EVENTS, EDGES_S)
% TIMES are point events (spikes, or any timestamps) and EVENTS the alignment
% anchors, both in seconds; EDGES_S are relative half-open bins [left,right).
% TRIAL_COUNTS is events x bins; RATE_HZ is the across-event mean per second.
% Nawrot et al. (1999). Events/trials may be dependent: interpret accordingly.
% Match spike_counts_edges: empty trains accepted, nonfinite spikes discarded.
%
%   SYNTAX
%     [centers_s,rate_hz,trial_counts] = peri_event_histogram(spike_times,event_times,edges_s)
%
%   INPUTS
%     spike_times: Real timestamp vector in seconds; empty accepted and nonfinite values
%       discarded.
%     event_times: Nonempty finite event vector in seconds, same time origin.
%     edges_s: Strictly increasing finite relative bin edges in seconds, >=2 values.
%
%   OUTPUTS
%     centers_s: Bin-center column in relative seconds.
%     rate_hz: Mean trial count divided by bin width, column in spikes/s.
%     trial_counts: Events-by-bins matrix, all bins half-open including final bin.
%
%   EXAMPLE
%     spikes = [0.95 1.02 1.1 1.98 2.04]; events = [1 2];
%     [centers_s, rate_hz, trial_counts] = peri_event_histogram(spikes,events,-0.2:0.05:0.2);
%     % Each trial is aligned to one event, with a shared relative time axis.
%
validateattributes(spike_times,{'numeric'},{'real'});
assert(isempty(spike_times) || isvector(spike_times));
assert(isvector(event_times) && isvector(edges_s) && numel(edges_s)>=2);
edges_s=double(edges_s(:).');
assert(all(diff(edges_s)>0) && all(isfinite(edges_s)));
assert(all(isfinite(event_times)));
assert(~isempty(event_times),'Provide at least one event');
trial_counts=zeros(numel(event_times),numel(edges_s)-1);
for k=1:numel(event_times)
    relative=double(spike_times(:))-event_times(k);
    trial_counts(k,:)=spike_counts_edges(relative,edges_s).';
end
width=diff(edges_s(:));
rate_hz=mean(trial_counts,1)'./width;
centers_s=(edges_s(1:end-1)'+edges_s(2:end)')/2;
end

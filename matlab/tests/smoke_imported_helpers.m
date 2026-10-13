%% Synthetic contracts for helpers imported from paper_con2phys.
% Run in a fresh MATLAB session. Not executed in the migration environment.
here=fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','path'));

% Silent units and half-open intervals, including the recording endpoint.
spikes={[0 .1 .2 .3],[]};
counts=spike_bins(spikes,[0 .1 .3]);
assert(isequal(counts,[1 0;2 0]));
rates=trial_features(spikes,[0 .1;.1 .3;.3 .3;NaN 1]);
assert(max(abs(rates(1:2,1)-[10;10]))<1e-12);
assert(all(rates(1:2,2)==0));
assert(all(all(isnan(rates(3:4,:)))));

% Decoded information: perfect balanced labels versus independent predictions.
y=[0;0;1;1];
assert(abs(decoded_mi(y,y)-1)<1e-12);
assert(abs(decoded_mi(y,[0;1;0;1]))<1e-12);
assert(isnan(decoded_mi(ones(4,1),ones(4,1))));

% Two disconnected unit-weight edges have optimal modularity 1/2.
w=[0 1 0 0;1 0 0 0;0 0 0 1;0 0 1 0];
assert(abs(greedy_modularity(w)-.5)<1e-12);
assert(isnan(greedy_modularity(zeros(4))));

% Both classes occur in every contiguous fold; one nonfinite row is excluded.
y=repmat([0;1],30,1); x=2*y-1; x(10)=NaN;
[score,detail]=decode_trials(x,y,42);
assert(score==1);
assert(isequal(detail.retained_rows,find(isfinite(x))));
assert(isequal(unique(detail.fold),(1:5)'));
assert(all(diff(detail.fold)>=0));
assert(all(detail.predicted==detail.observed));
assert(max(abs(sum(detail.probability,2)-1))<1e-12);
[again,other]=decode_trials(x,y,99);
assert(again==score && isequal(other.predicted,detail.predicted));
fprintf('Imported helper synthetic contracts passed.\n');

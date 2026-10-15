%% Synthetic regression tests: arbitrary event-aligned spike rasters.
% No real recordings or Signal Processing Toolbox required.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','path'));

% Repeated spikes, exact endpoint exclusion, invalid times, and ID mapping.
fs = 10;
ts = [0 .01 .049 .1 .1 .19 1.9 2 NaN -.1];
ids = int32([7 7 7 7 7 9 9 9 9 9]);
[S, labels, meta] = spike_raster_sparse(ts, ids, fs, 20);
assert(issparse(S) && isequal(size(S),[2 20]));
assert(isequal(labels,int32([7;9])));
assert(full(S(1,1))==3 && full(S(1,2))==2);
assert(full(S(2,2))==1 && full(S(2,20))==1);
assert(sum(nonzeros(S))==7 && meta.spikes_discarded==3);
assert(meta.spikes_kept==7 && S(2,1)==0);

% Empty spike arrays remain valid and yield no cluster rows.
[S0,ids0,meta0] = spike_raster_sparse([],int32([]),fs,20);
assert(issparse(S0) && isequal(size(S0),[0 20]));
assert(isempty(ids0) && meta0.spikes_kept==0);

% Events near recording edges, preserving multiplicities and NaN padding.
[R,lags,info] = event_aligned_raster(S,[0 .1 1.9],fs,[-.1 .1],1);
expected = [NaN 3 2; 3 2 0; 0 0 NaN];
assert(isequaln(R,expected));
assert(max(abs(lags-[-.1 0 .1]))<1e-12);
assert(isequal(info.event_indices,(1:3)'));
assert(~info.valid_bins(1,1) && ~info.valid_bins(3,3));

% Drop mode must retain only fully observed events.
[Rd,~,idrop] = event_aligned_raster(S,[0 .1 1.9],fs,[-.1 .1],1,'Boundary','drop');
assert(isequal(Rd,[3 2 0]) && isequal(idrop.event_indices,2));

% Non-grid events select the recording bin containing the event.
[Re,~,~] = event_aligned_raster(S,.199,fs,[0 0],2);
assert(isequal(Re,1));
[Rnone,~,~] = event_aligned_raster(S,[],fs,[-.1 .1],1);
assert(isequal(size(Rnone),[0 3]));

% Forward phase crossings, including phase wrapping and refractory spacing.
phase_t = (0:199)'/100;
phase = angle(exp(1i * (2*pi*2*phase_t)));
p = phase_crossing_events(phase,100,0,.3);
assert(numel(p)>=3);
assert(any(abs(p-.5)<.02) && any(abs(p-1)<.02));
assert(all(diff(p)>=.3-1e-12));

% Threshold excursions with onset, peak and midpoint event anchors.
envelope = [0 0 2 3 2 0 0 4 0 0]';
[peak_times, evt] = amplitude_threshold_events(envelope,fs,2);
assert(isequal(peak_times,[.3;.7]));
assert(abs(evt.start_s(1)-.2)<1e-12);
assert(abs(evt.stop_s(1)-.5)<1e-12);
[onsets,~] = amplitude_threshold_events(envelope,fs,2,'Anchor','onset');
assert(isequal(onsets,[.2;.7]));
[midpoints,~] = amplitude_threshold_events(envelope,fs,2, ...
    'Anchor','midpoint','MinDuration',.2);
assert(numel(midpoints)==1 && abs(midpoints-.35)<1e-12);
[none,empty_events] = amplitude_threshold_events(zeros(3,1),fs,2);
assert(isempty(none) && height(empty_events)==0);

% Ripple candidate intervals can be reduced to a clearly stated anchor.
ripple_start_s = .0;
ripple_stop_s = .2;
ripple_mid_s = (ripple_start_s+ripple_stop_s)/2;
[rr,~,~] = event_aligned_raster(S,ripple_mid_s,fs,[0 0],1);
assert(rr==2);

disp('event alignment regression checks completed')

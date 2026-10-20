%% Synthetic regression tests: event alignment of counts and continuous signals.
% No real recordings or Signal Processing Toolbox required.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..','path'));

% Repeated events, exact endpoint exclusion, invalid times, and label mapping.
fs = 10;
ts = [0 .01 .049 .1 .1 .19 1.9 2 NaN -.1];
ids = int32([7 7 7 7 7 9 9 9 9 9]);
[S, labels, meta] = sparse_count_matrix(ts, ids, fs, 20);
assert(issparse(S) && isequal(size(S),[2 20]));
assert(isequal(labels,int32([7;9])));
assert(full(S(1,1))==3 && full(S(1,2))==2);
assert(full(S(2,2))==1 && full(S(2,20))==1);
assert(sum(nonzeros(S))==7 && meta.events_discarded==3);
assert(meta.events_kept==7 && S(2,1)==0);

% Empty timestamp arrays remain valid and yield no label rows.
[S0,ids0,meta0] = sparse_count_matrix([],int32([]),fs,20);
assert(issparse(S0) && isequal(size(S0),[0 20]));
assert(isempty(ids0) && meta0.events_kept==0);

% Events near recording edges, preserving multiplicities and NaN padding.
[R,lags,info] = event_aligned_segments(S,[0 .1 1.9],fs,[-.1 .1],1);
expected = [NaN 3 2; 3 2 0; 0 0 NaN];
assert(isequaln(R,expected));
assert(max(abs(lags-[-.1 0 .1]))<1e-12);
assert(isequal(info.event_indices,(1:3)'));
assert(~info.valid_bins(1,1) && ~info.valid_bins(3,3));
assert(strcmp(info.anchor,'containing') && info.sample_dim==2);

% Drop mode must retain only fully observed events.
[Rd,~,idrop] = event_aligned_segments(S,[0 .1 1.9],fs,[-.1 .1],1,'Boundary','drop');
assert(isequal(Rd,[3 2 0]) && isequal(idrop.event_indices,2));

% Non-grid events select the recording bin containing the event.
[Re,~,~] = event_aligned_segments(S,.199,fs,[0 0],2);
assert(isequal(Re,1));
[Rnone,~,~] = event_aligned_segments(S,[],fs,[-.1 .1],1);
assert(isequal(size(Rnone),[0 3]));

% All rows by default: events x lags x rows, one slice per label row.
[Rall,~,iall] = event_aligned_segments(S,[0 .1 1.9],fs,[-.1 .1]);
assert(isequal(size(Rall),[3 3 2]) && isequaln(Rall(:,:,1),expected));
assert(isequaln(Rall(:,:,2),[NaN 0 1; 0 1 0; 0 1 NaN]) && isequal(iall.rows,[1 2]));

% Continuous channels x samples: values copied unchanged, edges NaN.
lfp = [1:20; 101:120];
[L,~,~] = event_aligned_segments(lfp,[.1 1.9],fs,[-.1 .1],[]);
assert(isequaln(L(:,:,1),[1 2 3; 19 20 NaN]));
assert(isequaln(L(:,:,2),[101 102 103; 119 120 NaN]));

% Samples x channels blocks (neuronal_read layout) give identical segments.
[Lt,~,it] = event_aligned_segments(lfp.',[.1 1.9],fs,[-.1 .1],[],'SampleDim',1);
assert(isequaln(Lt,L) && it.sample_dim==1);

% A vector is one row in either orientation when SampleDim is omitted.
[Lc,~,~] = event_aligned_segments(lfp(1,:).',[.1 1.9],fs,[-.1 .1]);
[Lr,~,~] = event_aligned_segments(lfp(1,:),[.1 1.9],fs,[-.1 .1],1);
assert(isequaln(Lc,L(:,:,1)) && isequaln(Lr,L(:,:,1)));

% Containing versus nearest anchors differ by at most one sample.
[Ac,~,ic] = event_aligned_segments(lfp,.16,fs,[0 0],1);
[An,~,in] = event_aligned_segments(lfp,.16,fs,[0 0],1,'Anchor','nearest');
assert(Ac==2 && An==3 && ic.center_samples==2 && in.center_samples==3);

% Event-triggered average equals the explicit nearest-sample loop.
fs_lfp = 500;
t_lfp = (0:fs_lfp*4-1)'/fs_lfp;
x = sin(2*pi*8*t_lfp) + .1*cos(2*pi*31*t_lfp);
ev = [.001 .5 1.2037 2.1 3.0 3.999];
[eta,eta_lags,used] = event_triggered_average(x,ev,fs_lfp,.2,.3);
offsets = (-round(.2*fs_lfp):round(.3*fs_lfp))';
acc = zeros(size(offsets)); n_ok = 0;
for k = 1:numel(ev)
    idx = round(ev(k)*fs_lfp)+1+offsets;
    if idx(1)<1 || idx(end)>numel(x), continue; end
    acc = acc + x(idx); n_ok = n_ok+1;
end
assert(used==n_ok && used==4 && iscolumn(eta) && iscolumn(eta_lags));
assert(max(abs(eta-acc/n_ok))<1e-12 && max(abs(eta_lags-offsets/fs_lfp))<1e-12);
[eta0,~,used0] = event_triggered_average(x,[],fs_lfp,.2,.3);
assert(used0==0 && all(isnan(eta0)));

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

% Interval events can be reduced to a clearly stated anchor.
ripple_start_s = .0;
ripple_stop_s = .2;
ripple_mid_s = (ripple_start_s+ripple_stop_s)/2;
[rr,~,~] = event_aligned_segments(S,ripple_mid_s,fs,[0 0],1);
assert(rr==2);

disp('event alignment regression checks completed')

%% Singleton sample axes must respect an explicit layout.
[one_sample,~,one_info] = event_aligned_segments([4;9],0,fs,[0 0],[], 'SampleDim',2);
assert(isequal(size(one_sample),[1 1 2]));
assert(isequal(reshape(one_sample,1,[]),[4 9]) && one_info.sample_dim==2);
[one_sample_t,~,~] = event_aligned_segments([4 9],0,fs,[0 0],[], 'SampleDim',1);
assert(isequal(one_sample,one_sample_t));

%% Existing entry points preserve metadata, shapes and anchors.
[old_s,old_labels,old_meta] = spike_raster_sparse(ts,ids,fs,20);
assert(isequal(old_s,S) && isequal(old_labels,labels));
assert(old_meta.spikes_input==numel(ts) && old_meta.spikes_kept==7);
assert(old_meta.spikes_discarded==3);
[old_r,old_lags,old_info] = event_aligned_raster(S,[0 .1 1.9],fs,[-.1 .1],1);
assert(isequaln(old_r,expected) && isequal(old_lags,lags));
assert(old_info.cluster_row==1 && isequal(old_info.event_indices,(1:3)'));
[old_single,~,~] = event_aligned_raster([4;9],0,fs,[0 0],2);
assert(old_single==9);
[old_eta,old_eta_lags,old_used] = spike_triggered_average(x,ev,fs_lfp,.2,.3);
assert(isequal(old_eta,eta) && isequal(old_eta_lags,eta_lags) && old_used==used);

% An average with no complete window is NaN, not a zero response.
[no_avg,~,no_used] = event_triggered_average(x,[-10 10],fs_lfp,.2,.3);
assert(no_used==0 && all(isnan(no_avg)));

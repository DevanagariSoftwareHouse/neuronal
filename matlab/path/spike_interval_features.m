function result = spike_interval_features(plan,analytic_signal,edge_seconds,amplitude_floor)
%SPIKE_INTERVAL_FEATURES Per-unit circular phase and amplitude per time window.
% R=spike_interval_features(PLAN,H,EDGE_SECONDS,AMPLITUDE_FLOOR).
% H is a full-session CPU analytic signal (Hilbert output). Spikes use the
% previous-or-coincident sample. Valid samples are finite, amplitude>floor,
% and inside [EDGE,N/fs-EDGE). Counts in PLAN include excluded phase spikes.
% Outputs W-by-units: phase_mean, phase_strength, amplitude_mean (single),
% phase_count (uint32). Empty windows yield NaN summaries and count zero.
% Prefix sums give O(spikes + windows*units), without one mask per window.
% Resultant length is descriptive, not a significance test.
if nargin<3, edge_seconds=0; end
if nargin<4, amplitude_floor=0; end
validateattributes(analytic_signal,{'single','double'},{'vector','numel',plan.N});
assert(~isa(analytic_signal,'gpuArray'),'Gather the analytic signal explicitly.');
validateattributes(edge_seconds,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(amplitude_floor,{'numeric'},{'scalar','real','finite','nonnegative'});
shape=size(plan.counts);
result=struct('phase_mean',nan(shape,'single'), ...
    'phase_strength',nan(shape,'single'),'amplitude_mean',nan(shape,'single'), ...
    'phase_count',zeros(shape,'uint32'));
for u=1:numel(plan.times)
    t=plan.times{u}; h=double(analytic_signal(plan.sample{u})); h=h(:);
    amp=abs(h);
    valid=isfinite(real(h)) & isfinite(imag(h)) & amp>amplitude_floor & ...
        t>=edge_seconds & t<plan.N/plan.fs-edge_seconds;
    c=zeros(size(t)); s=c; a=c;
    c(valid)=real(h(valid))./amp(valid);
    s(valid)=imag(h(valid))./amp(valid);
    a(valid)=amp(valid);
    left=double(plan.left{u}); right=double(plan.right{u});
    n=window_sum(double(valid),left,right);
    C=window_sum(c,left,right); S=window_sum(s,left,right);
    A=window_sum(a,left,right); magnitude=hypot(C,S);
    phase=atan2(S,C); strength=min(1,magnitude./n); amplitude=A./n;
    empty=n==0; strength(empty)=NaN; amplitude(empty)=NaN;
    % Prefix subtraction error grows with prefix length, not just bin count.
    phase(empty | magnitude<=64*eps*max(1,numel(t)))=NaN;
    result.phase_mean(:,u)=single(phase);
    result.phase_strength(:,u)=single(strength);
    result.amplitude_mean(:,u)=single(amplitude);
    result.phase_count(:,u)=uint32(n);
end
end
function sums=window_sum(values,left,right)
prefix=[0;cumsum(values)]; sums=prefix(right)-prefix(left);
end

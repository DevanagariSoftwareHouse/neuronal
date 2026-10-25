function plan = spike_interval_plan(times,unit_index,n_units,N,fs,bounds)
%SPIKE_INTERVAL_PLAN Reusable sorted spike indices for half-open time windows.
% P=spike_interval_plan(T,UNIT,NUNITS,N,FS,BOUNDS), BOUNDS=W-by-2 seconds.
% T is seconds relative to LFP sample 1 (time zero). UNIT contains one-based
% unit indices, not cluster IDs. Nonfinite/out-of-session times are excluded.
% Windows may overlap and need not be sorted. Invalid units are errors.
% Each unit is sorted once. Vectorized lower bounds avoid a W-by-spikes mask.
% P.counts is W-by-units uint32. Memory is approximately 12*W*units bytes
% plus spike arrays. Full-session endpoint N/FS is excluded.
validateattributes(times,{'numeric'},{'real'});
validateattributes(unit_index,{'numeric'},{'real'});
assert(isempty(times)||isvector(times),'Expected timestamp vector.');
assert(isempty(unit_index)||isvector(unit_index),'Expected unit vector.');
validateattributes(n_units,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(N,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(fs,{'numeric'},{'scalar','positive','real','finite'});
validateattributes(bounds,{'numeric'},{'2d','ncols',2,'real','finite'});
assert(size(bounds,1)>0 && all(bounds(:,1)>=0 & bounds(:,2)>bounds(:,1) & bounds(:,2)<=N/fs), ...
    'spike_interval:Bounds','Bounds must be nonempty intervals inside [0,N/fs].');
times=double(times(:)); unit_index=double(unit_index(:));
assert(numel(times)==numel(unit_index),'Timestamp/unit lengths differ.');
assert(all(isfinite(unit_index)&unit_index==fix(unit_index)&unit_index>=1&unit_index<=n_units), ...
    'spike_interval:Units','Unit indices must be integers in 1:n_units.');
keep=isfinite(times)&times>=0&times<N/fs;
plan=struct('N',double(N),'fs',double(fs),'bounds',double(bounds), ...
    'excluded_spikes',sum(~keep),'times',{cell(n_units,1)}, ...
    'sample',{cell(n_units,1)},'left',{cell(n_units,1)}, ...
    'right',{cell(n_units,1)},'counts',zeros(size(bounds,1),n_units,'uint32'));
times=times(keep); unit_index=unit_index(keep);
[unit_index,order]=sort(unit_index); times=times(order);
counts=accumarray(unit_index,ones(size(unit_index)),[n_units 1],@sum,0);
ends=cumsum(counts); starts=[0;ends(1:end-1)];
for u=1:n_units
    t=sort(times(starts(u)+1:ends(u)));
    assert(numel(t)<double(intmax('uint32')),'spike_interval:Size','Too many spikes for uint32 indices.');
    a=lower_bound(t,bounds(:,1)); b=lower_bound(t,bounds(:,2));
    plan.times{u}=t;
    % Previous-or-coincident LFP sample; no phase interpolation.
    plan.sample{u}=min(N,floor(t*fs)+1);
    plan.left{u}=uint32(a); plan.right{u}=uint32(b);
    plan.counts(:,u)=uint32(b-a);
end
end
function index=lower_bound(sorted,query)
% First index with sorted(index)>=query; numel(sorted)+1 if absent.
lo=ones(size(query)); hi=repmat(numel(sorted)+1,size(query));
while any(lo<hi)
    active=find(lo<hi); mid=floor((lo(active)+hi(active))/2);
    before=sorted(mid)<query(active);
    lo(active(before))=mid(before)+1;
    hi(active(~before))=mid(~before);
end
index=lo;
end

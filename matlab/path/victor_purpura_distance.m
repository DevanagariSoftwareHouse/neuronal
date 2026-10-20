function distance = victor_purpura_distance(spikes_a,spikes_b,q)
%VICTOR_PURPURA_DISTANCE Spike-train edit distance; Victor & Purpura 1997.
% DOI: 10.1088/0954-898X/8/2/003. Spike times in seconds.
% Insert/delete each cost 1, shift from t to s costs q*abs(t-s).
%
%   SIGNATURE DESCRIPTION
%     spikes_a — the spikes a value; expected shape, units, and constraints are stated in the notes above.
%     spikes_b — the spikes b value; expected shape, units, and constraints are stated in the notes above.
%     q — the q value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     distance — spike-train distance under the supplied cost parameter.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     distance = victor_purpura_distance(spikes_a, spikes_b, q);
%
assert((isvector(spikes_a) || isempty(spikes_a)) && ...
    (isvector(spikes_b) || isempty(spikes_b)) && isscalar(q));
assert(isfinite(q) && q>=0);
a=sort(double(spikes_a(:))); b=sort(double(spikes_b(:)));
assert(all(isfinite(a)) && all(isfinite(b)));
if numel(b)>numel(a), tmp=a; a=b; b=tmp; end
m=numel(b); n=numel(a);
previous=0:m;
for i=1:n
    current=zeros(1,m+1);
    current(1)=i;
    for j=1:m
        current(j+1)=min([previous(j+1)+1,current(j)+1, ...
            previous(j)+q*abs(a(i)-b(j))]);
    end
    previous=current;
end
distance=previous(end);
end

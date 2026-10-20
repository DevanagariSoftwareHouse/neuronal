function result = maxstat_permutation_test(a,b,statfun,B,tail)
%MAXSTAT_PERMUTATION_TEST Joint label permutation and max-T correction.
% statfun returns a row vector of test statistics over features.
%
%   SIGNATURE DESCRIPTION
%     a — the a value; expected shape, units, and constraints are stated in the notes above.
%     b — the b value; expected shape, units, and constraints are stated in the notes above.
%     statfun — function handle that computes the requested statistic.
%     B — number of bootstrap/permutation/surrogate draws.
%     tail — the tail value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     result — result structure containing the estimates and diagnostics described above.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     result = maxstat_permutation_test(a, b, statfun, B, tail);
%
if nargin<4||isempty(B), B=999; end
if nargin<5||isempty(tail), tail='two-sided'; end
assert(size(a,2)==size(b,2)&&all(isfinite(a(:)))&&all(isfinite(b(:))));
na=size(a,1); pool=[a;b]; n=size(pool,1);
obs=reshape(statfun(a,b),1,[]); null=zeros(B,numel(obs));
for k=1:B
    p=randperm(n);
    v=reshape(statfun(pool(p(1:na),:),pool(p(na+1:end),:)),1,[]);
    assert(numel(v)==numel(obs)&&all(isfinite(v)));
    null(k,:)=v;
end
switch lower(char(tail))
    case 'two-sided', transformed=abs(null); target=abs(obs);
    case 'right', transformed=null; target=obs;
    case 'left', transformed=-null; target=-obs;
    otherwise, error('Unknown tail');
end
maxnull=max(transformed,[],2);
p=(1+sum(bsxfun(@ge,maxnull,target),1))/(B+1);
result=struct('observed',obs,'null',null,'p_corrected',p,'max_null',maxnull);
end

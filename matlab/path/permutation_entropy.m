function [entropy_value,counts,patterns] = permutation_entropy(signal,order,delay)
%PERMUTATION_ENTROPY Normalized ordinal-pattern entropy (0 to 1).
% Ties are excluded. Akin to con2phys q15; window selection is caller's job.
%
%   SYNTAX
%     [entropy_value,counts,patterns] = permutation_entropy(signal,order,delay)
%
%   INPUTS
%     signal: Finite numeric vector.
%     order: Integer ordinal pattern length from 2 to 7; default 3.
%     delay: Positive integer sample lag; default 1; numel(signal)-(order-1)*delay >=10.
%
%   OUTPUTS
%     entropy_value: Scalar normalized ordinal entropy in [0,1], NaN if all patterns have ties.
%     counts: Column of counts for observed tie-free patterns.
%     patterns: One observed index permutation per row.
%
%   EXAMPLE
%     rng(7); x = randn(1000,1);
%     [h, counts, patterns] = permutation_entropy(x,3,1);
%     % delay is in samples; ties are excluded rather than randomly broken.
%
if nargin<2 || isempty(order), order=3; end
if nargin<3 || isempty(delay), delay=1; end
x=double(signal(:)); assert(all(isfinite(x)),'Signal must be finite');
assert(order>=2 && order<=7 && order==floor(order), ...
    'Supported orders are integers 2..7');
assert(delay>=1 && delay==floor(delay),'Delay must be a positive integer');
n=numel(x)-(order-1)*delay;
assert(n>=10,'Too few ordinal patterns');
p=zeros(n,order); valid=true(n,1);
for k=1:n
    v=x(k+(0:order-1)*delay);
    valid(k)=numel(unique(v))==order;
    [~,p(k,:)]=sort(v);
end
p=p(valid,:);
if isempty(p), entropy_value=NaN; counts=[]; patterns=[]; return; end
[patterns,~,idx]=unique(p,'rows');
counts=accumarray(idx,1);
prob=counts/sum(counts);
entropy_value=-sum(prob.*log(prob))/gammaln(order+1);
end

function bits = transfer_entropy(source,target)
%TRANSFER_ENTROPY First-order DISCRETE lagged conditional mutual information.
% Timme & Lapish (2018): exploratory plug-in estimator, no bias correction.
% TE = I(target[t]; source[t-1] | target[t-1]); no causal claim.
%
%   SYNTAX
%     bits = transfer_entropy(source,target)
%
%   INPUTS
%     source: Finite discrete numeric label vector with >=10 samples.
%     target: Matching discrete label vector sampled at the same times.
%
%   OUTPUTS
%     bits: Nonnegative scalar first-order plug-in I(target[t];source[t-1] given target[t-1])
%       in bits, without bias correction.
%
%   EXAMPLE
%     rng(7); source = randi([0 1],1000,1); target = [0;source(1:end-1)];
%     bits = transfer_entropy(source,target);
%     % One-sample delayed copying provides a toy directed dependence.
%
s=double(source(:)); y=double(target(:));
assert(numel(s)==numel(y) && numel(y)>=10 && ...
    all(isfinite(s)) && all(isfinite(y)));
current=y(2:end); past=y(1:end-1); source_past=s(1:end-1);
sets={[current past],[past source_past],past, ...
    [current past source_past]};
h=zeros(1,4);
for k=1:4
    [~,~,index]=unique(sets{k},'rows');
    counts=accumarray(index,1);
    p=counts/sum(counts);
    h(k)=-sum(p.*log2(p));
end
bits=h(1)+h(2)-h(3)-h(4);
bits=max(0,bits);
end

function result = paired_signflip_test(before,after,draws,seed)
%PAIRED_SIGNFLIP_TEST Two-sided paired sign-flip randomization test.
% Maris & Oostenveld (2007) motivate permutation inference; NOT cluster-based.
%
%   SYNTAX
%     result = paired_signflip_test(before,after,draws,seed)
%
%   INPUTS
%     before: Finite numeric vector, >=2 matched units.
%     after: Matching finite vector.
%     draws: Positive integer sign-flip count; default 2000.
%     seed: Local mt19937ar seed; default 42.
%
%   OUTPUTS
%     result: Struct with observed_difference (mean after-before), p_two_sided and draws.
%
%   EXAMPLE
%     before = [5;7;6;8;4]; after = before+[1;2;0;1;3];
%     result = paired_signflip_test(before,after,1000,7);
%     % Valid sign-flip inference requires sign symmetry under the null.
%
if nargin<3 || isempty(draws), draws=2000; end
if nargin<4 || isempty(seed), seed=42; end
a=double(before(:)); b=double(after(:));
assert(numel(a)==numel(b) && numel(a)>=2 && all(isfinite(a)) && ...
    all(isfinite(b)) && draws>=1);
delta=b-a; observed=mean(delta);
stream=RandStream('mt19937ar','Seed',seed);
extreme=0;
for k=1:draws
    signs=2*(rand(stream,numel(delta),1)>.5)-1;
    extreme=extreme+(abs(mean(delta.*signs))>=abs(observed));
end
result.observed_difference=observed;
result.p_two_sided=(1+extreme)/(draws+1);
result.draws=draws;
end

function scaling = population_dimension_scaling(activity,unit_counts,repetitions,seed)
%POPULATION_DIMENSION_SCALING Participation ratio for sampled units.
% Williamson et al. (2016), doi:10.1371/journal.pcbi.1005141.
%
%   SYNTAX
%     scaling = population_dimension_scaling(activity,unit_counts,repetitions,seed)
%
%   INPUTS
%     activity: Finite observations-by-units matrix, >=3 rows and >=2 units.
%     unit_counts: Nonempty vector of integer subset sizes from 2 to the available units.
%     repetitions: Positive integer subset draws per size; default 25.
%     seed: Local mt19937ar seed; default 42.
%
%   OUTPUTS
%     scaling: Struct with unit_counts (column), dimension_samples (repetitions-by-sizes),
%       mean_dimension (column), seed.
%
%   EXAMPLE
%     rng(7); x = randn(100,10);
%     scaling = population_dimension_scaling(x,[2 5 10],20,7);
%     % Variability across subsets is not an animal-level confidence interval.
%
if nargin<3 || isempty(repetitions), repetitions=25; end
if nargin<4 || isempty(seed), seed=42; end
x=double(activity); [n,p]=size(x);
assert(n>=3 && p>=2 && all(isfinite(x(:))));
counts=double(unit_counts(:));
assert(~isempty(counts) && all(counts==floor(counts)) && ...
    all(counts>=2) && all(counts<=p));
assert(repetitions>=1 && repetitions==floor(repetitions));
stream=RandStream('mt19937ar','Seed',seed);
values=nan(repetitions,numel(counts));
for i=1:numel(counts)
    for k=1:repetitions
        [~,idx]=sort(rand(stream,1,p));
        values(k,i)=participation_ratio(x(:,idx(1:counts(i))));
    end
end
scaling.unit_counts=counts;
scaling.dimension_samples=values;
scaling.mean_dimension=mean(values,1)';
scaling.seed=seed;
end

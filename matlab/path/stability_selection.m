function out = stability_selection(x,selectorfun,B,fraction)
%STABILITY_SELECTION Selection frequencies across random subsamples.
% selectorfun(subsample) returns logical vector of selected features.
% No formal error bound without additional assumptions/calibration.
%
%   SYNTAX
%     out = stability_selection(x,selectorfun,B,fraction)
%
%   INPUTS
%     x: Observations-by-features matrix, >=4 rows.
%     selectorfun: Function of a row subsample returning a fixed-length logical selection
%       vector.
%     B: Integer subsamples >=20; default 200.
%     fraction: Subsample fraction, default 0.5; 2 <= floor(n*fraction) < n.
%
%   OUTPUTS
%     out: Struct with selection_frequency (1-by-selected-vector-length), draws and fraction.
%
%   EXAMPLE
%     rng(7); x = randn(100,4)+[0 0.5 0 1];
%     selector = @(z) abs(mean(z,1))>0.3;
%     out = stability_selection(x,selector,200,0.5);
%     % Frequencies measure selector stability, without a formal false-discovery bound.
%
if nargin<3||isempty(B), B=200; end
if nargin<4||isempty(fraction), fraction=.5; end
n=size(x,1); m=floor(n*fraction);
assert(n>=4&&m>=2&&m<n&&B>=20);
first=reshape(logical(selectorfun(x(randperm(n,m),:))),1,[]);
counts=double(first);
for k=2:B
    v=reshape(logical(selectorfun(x(randperm(n,m),:))),1,[]);
    assert(numel(v)==numel(first));
    counts=counts+double(v);
end
out=struct('selection_frequency',counts/B,'draws',B,'fraction',fraction);
end

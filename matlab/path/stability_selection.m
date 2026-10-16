function out = stability_selection(x,selectorfun,B,fraction)
%STABILITY_SELECTION Selection frequencies across random subsamples.
% selectorfun(subsample) returns logical vector of selected features.
% No formal error bound without additional assumptions/calibration.
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

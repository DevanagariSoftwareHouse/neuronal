function [y,mask] = filter_despike(x,indices,half_width)
%FILTER_DESPIKE Interpolate explicitly marked spike neighborhoods.
% [Y,MASK] = filter_despike(X,INDICES,HALF_WIDTH)
% INDICES: one-based sample indices shared across channels, not seconds.
% HALF_WIDTH: integer samples. Overlapping neighborhoods are merged.
% Boundary neighborhoods without clean samples on both sides are rejected.
% This removes voltage locally; it is not generative spike subtraction.
% MASK is true where samples were replaced. X is samples-by-channels/vector.
% Example: [y,mask]=filter_despike(x,[500 1000],3);
[x,row]=filter_input(x); n=size(x,1);
validateattributes(half_width,{'numeric'},{'scalar','integer','nonnegative'});
mask=false(n,1);
if ~isempty(indices)
    validateattributes(indices,{'numeric'},{'vector','integer','>=',1,'<=',n});
    for k=1:numel(indices)
        mask(max(1,double(indices(k))-half_width):min(n,double(indices(k))+half_width))=true;
    end
end
assert(~mask(1) && ~mask(end),'Cannot interpolate edge artifacts without bracketing data');
y=x;
if any(mask), y(mask,:)=interp1(find(~mask),x(~mask,:),find(mask),'linear'); end
if row, y=y.'; end
end

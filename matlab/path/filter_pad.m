function [y, keep] = filter_pad(x,n,mode)
%FILTER_PAD Explicit sample padding with indices to crop the result.
% [Y,KEEP] = filter_pad(X,N,MODE); MODE='reflect','replicate', or 'zero'.
% Reflection excludes endpoint duplication; N <= samples-1 for reflect.
% X is samples-by-channels or a vector; Y preserves vector orientation.
% Example: [xp,keep]=filter_pad(x,100,'reflect'); % crop as yp(keep,:)
[x,row]=filter_input(x);
validateattributes(n,{'numeric'},{'scalar','integer','nonnegative'});
mode=validatestring(mode,{'reflect','replicate','zero'});
switch mode
    case 'reflect'
        assert(n<size(x,1),'Reflection length must be smaller than record');
        y=[x(n+1:-1:2,:);x;x(end-1:-1:end-n,:)];
    case 'replicate', y=[repmat(x(1,:),n,1);x;repmat(x(end,:),n,1)];
    case 'zero', y=[zeros(n,size(x,2));x;zeros(n,size(x,2))];
end
keep=n+(1:size(x,1));
if row, y=y.'; end
end

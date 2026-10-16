function xp = local_permutation_surrogate(x,conditioning,k)
%LOCAL_PERMUTATION_SURROGATE Approximate conditional nearest-neighbor shuffle.
% x rows correspond to observations; conditioning rows to matching states.
% Heuristic neighbor-restricted permutation, NOT an exact conditional null.
% Check calibration before TE inference (Shorten et al., 2020).
assert(isnumeric(x)&&isnumeric(conditioning)&&ismatrix(x)&&ismatrix(conditioning));
n=size(x,1); assert(size(conditioning,1)==n&&n>=3);
assert(all(isfinite(x(:)))&&all(isfinite(conditioning(:))));
if nargin<3||isempty(k), k=min(10,n-1); end
assert(k>=1&&k<n&&k==floor(k));
z=double(conditioning); xp=zeros(size(x));
for i=1:n
    d=sum((z-z(i,:)).^2,2); d(i)=inf;
    [~,ord]=sort(d);
    xp(i,:)=x(ord(randi(k)),:);
end
end

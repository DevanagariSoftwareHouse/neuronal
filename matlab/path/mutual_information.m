function bits = mutual_information(x,y)
%MUTUAL_INFORMATION Empirical discrete plug-in MI in bits.
% Panzeri & Treves (1996): strong finite-sample bias; no correction here.
% Each event must have a finite numerical label, not a continuous measurement.
%
%   SYNTAX
%     bits = mutual_information(x,y)
%
%   INPUTS
%     x: Finite numeric discrete-label vector, >=2 observations.
%     y: Matching finite numeric discrete-label vector.
%
%   OUTPUTS
%     bits: Scalar empirical mutual information in bits, without bias correction.
%
%   EXAMPLE
%     x = [0;0;1;1]; y = [1;1;0;0];
%     bits = mutual_information(x,y);
%     % These balanced, perfectly related labels give 1 bit.
%
x=double(x(:)); y=double(y(:));
assert(numel(x)==numel(y) && numel(x)>=2 && ...
    all(isfinite(x)) && all(isfinite(y)));
[~,~,ix]=unique(x); [~,~,iy]=unique(y);
counts=accumarray([ix iy],1);
prob=counts/sum(counts(:)); px=sum(prob,2); py=sum(prob,1);
expected=px*py;
mask=prob>0;
bits=sum(prob(mask).*log2(prob(mask)./expected(mask)));
end

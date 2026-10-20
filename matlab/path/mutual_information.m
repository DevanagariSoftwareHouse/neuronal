function bits = mutual_information(x,y)
%MUTUAL_INFORMATION Empirical discrete plug-in MI in bits.
% Panzeri & Treves (1996): strong finite-sample bias; no correction here.
% Each event must have a finite numerical label, not a continuous measurement.
%
%   SIGNATURE DESCRIPTION
%     x — input observations or signal (see the function summary for its expected shape).
%     y — the y value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     bits — mutual/transfer information in bits.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     bits = mutual_information(x, y);
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

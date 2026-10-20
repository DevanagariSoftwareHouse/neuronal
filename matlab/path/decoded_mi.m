function info=decoded_mi(y,pred)
%DECODED_MI Empirical mutual information between observed and predicted labels.
%
%   SYNTAX
%     info=decoded_mi(y,pred)
%
%   INPUTS
%     y: Column vector of observed numeric labels.
%     pred: Matching column vector of predicted labels; nonfinite pairs are removed.
%
%   OUTPUTS
%     info: Scalar plug-in mutual information in bits; NaN for no pairs or fewer than two
%       observed classes.
%
%   EXAMPLE
%     y = [0;0;1;1]; pred = [0;0;1;1];
%     info = decoded_mi(y,pred);
%     % Perfect prediction of these balanced labels gives 1 bit.
%
    ok=isfinite(y) & isfinite(pred); y=y(ok); pred=pred(ok); info=nan;
    if isempty(y) || numel(unique(y))<2, return; end
    classes=unique([y;pred]); p=zeros(numel(classes));
    for i=1:numel(classes)
        for j=1:numel(classes), p(i,j)=mean(y==classes(i) & pred==classes(j)); end
    end
    independent=sum(p,2)*sum(p,1); nz=p>0;
    info=sum(p(nz).*log2(p(nz)./independent(nz)));
end

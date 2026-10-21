function info=decoded_mi(y,pred)
%DECODED_MI Plug-in mutual information (bits) between labels and predictions.
% INFO = DECODED_MI(Y, PRED) uses the empirical joint distribution of the
% finite (Y,PRED) pairs, e.g. DETAIL.observed/predicted of decode_trials.
% INFO is NaN when no pair remains or Y has fewer than two classes.
% Finite-sample bias is not corrected; compare with a label-shuffle null.
% This is decoded information, a lower bound only under assumptions.
% See also decode_trials, mutual_information.
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

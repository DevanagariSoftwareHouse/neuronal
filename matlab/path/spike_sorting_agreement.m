function out = spike_sorting_agreement(reference,estimated,tolerance_seconds)
%SPIKE_SORTING_AGREEMENT One-to-one temporal event matching for a unit.
% SpikeForest/SpikeInterface benchmark primitive, not multiunit assignment.
%
%   SYNTAX
%     out = spike_sorting_agreement(reference,estimated,tolerance_seconds)
%
%   INPUTS
%     reference: Finite reference spike timestamps in seconds; sorted internally.
%     estimated: Finite detected timestamps in seconds; sorted internally.
%     tolerance_seconds: Nonnegative inclusive matching tolerance; default 0.0005.
%
%   OUTPUTS
%     out: Struct: true_positives, false_positives, false_negatives, precision, recall, f1 and
%       tolerance_seconds; zero denominators yield NaN.
%
%   EXAMPLE
%     out = spike_sorting_agreement([0.1 0.2 0.3],[0.1001 0.2 0.4],0.0005);
%     % Two one-to-one matches, one false positive and one false negative.
%
if nargin<3 || isempty(tolerance_seconds), tolerance_seconds=.0005; end
a=sort(double(reference(:))); b=sort(double(estimated(:)));
assert(all(isfinite(a)) && all(isfinite(b)) && ...
    isfinite(tolerance_seconds) && tolerance_seconds>=0);
i=1; j=1; tp=0;
while i<=numel(a) && j<=numel(b)
    delta=a(i)-b(j);
    if abs(delta)<=tolerance_seconds
        tp=tp+1; i=i+1; j=j+1;
    elseif delta<0
        i=i+1;
    else
        j=j+1;
    end
end
fp=numel(b)-tp; fn=numel(a)-tp;
out.true_positives=tp; out.false_positives=fp; out.false_negatives=fn;
out.precision=NaN; out.recall=NaN; out.f1=NaN;
if tp+fp>0, out.precision=tp/(tp+fp); end
if tp+fn>0, out.recall=tp/(tp+fn); end
if 2*tp+fp+fn>0, out.f1=2*tp/(2*tp+fp+fn); end
out.tolerance_seconds=tolerance_seconds;
end

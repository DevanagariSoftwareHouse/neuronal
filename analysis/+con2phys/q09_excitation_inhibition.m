%% Q9: broad/narrow waveform count ratio; not physiological E/I.
qid='q09'; con2phys.q00_prepare
[narrow,width]=waveform_class(data,qcfg); values=cell(3,1); counts=zeros(3,2);
for a=1:3
    x=narrow(qctx.area==a); x=x(isfinite(x)); values{a}=x;
    counts(a,:)=[sum(x==0) sum(x==1)];
end
% Bootstrap finite narrow proportions, then invert the confidence set.
q09=summarize_questionnaire(values,qctx.labels,'broad/narrow cluster ratio', ...
    'Transformed interval for narrow proportion: ratio=(1-p)/p.',qcfg,'unit');
q09.proportion_summary=q09.summary;
for a=1:3
    p=q09.proportion_summary.mean(a);
    bounds=[q09.proportion_summary.ci_low(a) q09.proportion_summary.ci_high(a)];
    if isfinite(p), q09.summary.mean(a)=(1-p)/p; end
    if all(isfinite(bounds))
        bounds=max(0,min(1,bounds)); % intersect proportion set with parameter space
        q09.summary.ci_low(a)=(1-bounds(2))/bounds(2);
        q09.summary.ci_high(a)=(1-bounds(1))/bounds(1);
    end
    if p==0 || p==1
        % Empirical resampling cannot quantify an unseen class probability.
        q09.summary.ci_low(a)=NaN; q09.summary.ci_high(a)=NaN;
        q09.inference{a}.status='boundary proportion: ratio interval unavailable';
    end
end
q09.summary.broad_units=counts(:,1); q09.summary.narrow_units=counts(:,2);
q09.answer='Not enough data to identify physiological excitation/inhibition.';
q09.limitations='Inference draws describe narrow proportions; displayed ratio intervals are transformed. Boundary samples require an explicit count model.';
q09.width_ms=width; q09.provenance=qctx.provenance;
disp(q09.summary)

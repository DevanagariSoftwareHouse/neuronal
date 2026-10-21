function [template_id,similarity] = template_match_waveforms(waveforms,templates)
%TEMPLATE_MATCH_WAVEFORMS Cosine waveform-template similarities.
% Rows = detected waveforms/templates, columns = aligned samples.
% This is a primitive, not a full Rossant/Kilosort sorter.
%
%   SYNTAX
%     [template_id,similarity] = template_match_waveforms(waveforms,templates)
%
%   INPUTS
%     waveforms: Finite waveforms-by-samples matrix; every row must have nonzero norm.
%     templates: Finite templates-by-matching-samples matrix; every row must have nonzero norm.
%
%   OUTPUTS
%     template_id: Waveforms-by-1 best matching template row indices (1-based).
%     similarity: Waveforms-by-1 maximum cosine similarities in [-1,1].
%
%   EXAMPLE
%     templates = [0 -1 0.5 0;0 -0.2 -1 0.5]; waves = [2*templates(1,:);templates(2,:)];
%     [id, similarity] = template_match_waveforms(waves,templates);
%     % Scaling a waveform does not change its cosine match.
%
x=double(waveforms); t=double(templates);
assert(ismatrix(x) && ismatrix(t) && size(x,2)==size(t,2));
assert(all(isfinite(x(:))) && all(isfinite(t(:))));
xn=sqrt(sum(x.^2,2)); tn=sqrt(sum(t.^2,2));
assert(all(xn>0) && all(tn>0),'Zero-norm waveform or template');
scores=(x*t')./(xn*tn');
[similarity,template_id]=max(scores,[],2);
end

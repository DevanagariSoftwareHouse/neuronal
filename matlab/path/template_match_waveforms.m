function [template_id,similarity] = template_match_waveforms(waveforms,templates)
%TEMPLATE_MATCH_WAVEFORMS Cosine waveform-template similarities.
% Rows = detected waveforms/templates, columns = aligned samples.
% This is a primitive, not a full Rossant/Kilosort sorter.
%
%   SIGNATURE DESCRIPTION
%     waveforms — the waveforms value; expected shape, units, and constraints are stated in the notes above.
%     templates — the templates value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     template_id — the returned value; see the summary above for meaning and units.
%     similarity — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [template_id, similarity] = template_match_waveforms(waveforms, templates);
%
x=double(waveforms); t=double(templates);
assert(ismatrix(x) && ismatrix(t) && size(x,2)==size(t,2));
assert(all(isfinite(x(:))) && all(isfinite(t(:))));
xn=sqrt(sum(x.^2,2)); tn=sqrt(sum(t.^2,2));
assert(all(xn>0) && all(tn>0),'Zero-norm waveform or template');
scores=(x*t')./(xn*tn');
[similarity,template_id]=max(scores,[],2);
end

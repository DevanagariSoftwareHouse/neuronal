function [narrow,width] = waveform_class(data,cfg)
%WAVEFORM_CLASS Classify finite negative-trough/positive-peak waveforms.
% Outputs are unit-column vectors; invalid waveforms stay NaN.
n=size(data.waveform,1); width=nan(n,1); narrow=nan(n,1);
for u=1:n
    w=double(data.waveform(u,:));
    if any(~isfinite(w))||isempty(w)||std(w)==0, continue; end
    [v,k]=min(w);
    if v>=0||k==numel(w)||max(w(k+1:end))<=0, continue; end
    width(u)=waveform_trough_to_peak(w,cfg.waveform_srate);
    narrow(u)=double(width(u)<cfg.narrow_ms);
end
end

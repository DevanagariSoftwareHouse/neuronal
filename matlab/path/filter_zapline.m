function y = filter_zapline(x,fs,line_hz,nremove)
%FILTER_ZAPLINE Adapter to the original NoiseTools NT_ZAPLINE implementation.
% Y = filter_zapline(X,FS,LINE_HZ,NREMOVE); X: samples-by-channels.
% Requires NoiseTools nt_zapline and its dependencies on the MATLAB path.
% LINE_HZ is converted to cycles/sample. NREMOVE must be explicitly chosen.
% This function does not implement Zapline-plus or install NoiseTools.
% Example (NoiseTools installed): y=filter_zapline(x,500,60,1);
filter_require('nt_zapline');
[x,~]=filter_input(x);
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(line_hz,{'numeric'},{'scalar','real','finite','positive','<',fs/2});
validateattributes(nremove,{'numeric'},{'scalar','integer','>=',0,'<',size(x,2)});
assert(size(x,2)>1,'ZapLine needs multiple channels');
y=nt_zapline(x,line_hz/fs,nremove);
assert(isequal(size(y),size(x)) && all(isfinite(y(:))),'Invalid backend output');
end

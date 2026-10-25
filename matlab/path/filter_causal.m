function [y, state] = filter_causal(x, d, state)
%FILTER_CAUSAL Apply design to a chunk and return exact continuation states.
% [Y,STATE] = filter_causal(X,D,STATE); omit STATE for zero initial conditions.
% X: samples-by-channels or vector. Y preserves vector orientation.
% STATE belongs to the exact D and channel count; do not reuse after redesign.
% Example: d=filter_butterworth(500,[0 30],4);
%   [a,s]=filter_causal(x(1:1000,:),d); [b,s]=filter_causal(x(1001:end,:),d,s);
if nargin<3, state=[]; end
[y,row]=filter_input(x);
if ~isempty(state)
    assert(isstruct(state) && isequal(state.design,d) && state.channels==size(y,2), ...
        'State must match design and channel count');
end
if strcmp(d.kind,'identity')
    z={};
elseif strcmp(d.form,'sos')
    z=cell(size(d.sos,1),1); y=y*d.gain;
    for k=1:size(d.sos,1)
        zi=[]; if ~isempty(state), zi=state.z{k}; end
        [y,z{k}]=filter(d.sos(k,1:3),d.sos(k,4:6),y,zi,1);
    end
else
    zi=[]; if ~isempty(state), zi=state.z{1}; end
    [y,zf]=filter(d.b,d.a,y,zi,1); z={zf};
end
state=struct('design',d,'channels',size(y,2),'z',{z});
if row, y=y.'; end
end

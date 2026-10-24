function state = filter_state(d, channels)
%FILTER_STATE Construct zero continuation states for a design and channels.
% S = filter_state(D,CHANNELS); pass S to FILTER_CAUSAL for each chunk.
% Example: s=filter_state(filter_butterworth(500,[0 30],4),2);
validateattributes(channels,{'numeric'},{'scalar','integer','positive'});
if strcmp(d.kind,'identity'), z={};
elseif strcmp(d.form,'sos'), z=repmat({zeros(2,channels)},size(d.sos,1),1);
else, z={zeros(max(numel(d.a),numel(d.b))-1,channels)}; end
state=struct('design',d,'channels',channels,'z',{z});
end

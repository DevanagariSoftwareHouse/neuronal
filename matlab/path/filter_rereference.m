function [y,reference] = filter_rereference(x,method,channels)
%FILTER_REREFERENCE Common mean/median or explicit bipolar channel pairs.
% [Y,R] = filter_rereference(X,METHOD,CHANNELS); X: samples-by-channels.
% For 'mean'/'median', CHANNELS selects reference channels (default all).
% For 'bipolar', CHANNELS is K-by-2 pairs; Y(:,k)=X(:,a)-X(:,b), R=[].
% Re-reference within an appropriate recording group; shared signal may go.
% Example: y=filter_rereference(x,'median',1:16);
[x,~]=filter_input(x);
method=validatestring(method,{'mean','median','bipolar'});
if nargin<3 || isempty(channels)
    assert(~strcmp(method,'bipolar'),'Supply bipolar pairs');
    channels=1:size(x,2);
end
validateattributes(channels,{'numeric'},{'real','finite','integer','nonempty','>=',1,'<=',size(x,2)});
if strcmp(method,'bipolar')
    assert(size(channels,2)==2 && all(channels(:,1)~=channels(:,2)),'Supply distinct channel pairs');
    y=x(:,channels(:,1))-x(:,channels(:,2)); reference=[];
else
    assert(isvector(channels) && numel(unique(channels))==numel(channels),'Reference channels must be unique');
    if strcmp(method,'mean'), reference=mean(x(:,channels),2);
    else, reference=median(x(:,channels),2); end
    y=bsxfun(@minus,x,reference);
end
end

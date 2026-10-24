function d = filter_design(method, fs, band, order, varargin)
%FILTER_DESIGN Design a classical pass filter independently of application.
% D = filter_design(METHOD,FS,[LOW HIGH],ORDER,...)
% METHOD: butterworth, cheby1, cheby2, elliptic, windowed_fir, equiripple_fir.
% Band endpoints 0 and FS/2 select low/high/identity responses automatically.
% Options: RippleDB=.5, StopDB=60, Window='hamming', TransitionHz (required
% for equiripple), Weights (one positive weight per constrained band).
% IIR output uses SOS+gain; FIR output uses b,a. ORDER is prototype order
% for IIR (bandpass doubles it), and even polynomial order for FIR.
% Cutoffs mean different things across designs; inspect actual responses.
% Example: d = filter_design('butterworth',500,[4 12],4);
%          y = filter_forward_backward(randn(5000,1),d);
validateattributes(fs,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(band,{'numeric'},{'vector','numel',2,'real','finite','>=',0,'<=',fs/2});
validateattributes(order,{'numeric'},{'scalar','integer','positive'});
band = double(band(:)'); assert(band(1)<band(2),'Band must have positive width');
p = inputParser;
addParameter(p,'RippleDB',.5); addParameter(p,'StopDB',60);
addParameter(p,'Window','hamming'); addParameter(p,'TransitionHz',[]);
addParameter(p,'Weights',[]); parse(p,varargin{:}); o = p.Results;
validateattributes(o.RippleDB,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(o.StopDB,{'numeric'},{'scalar','real','finite','positive'});
method = validatestring(method,{'butterworth','cheby1','cheby2','elliptic','windowed_fir','equiripple_fir'});
d = struct('method',method,'fs',fs,'band',band,'order',order, ...
    'kind','bandpass','form','ba','b',1,'a',1,'sos',[],'gain',1,'options',o);
if band(1)==0 && band(2)==fs/2, d.kind='identity'; return; end
wn = band/(fs/2);
if band(1)==0, d.kind='low'; wn=wn(2); end
if band(2)==fs/2, d.kind='high'; wn=wn(1); end
switch method
    case 'butterworth', [z,poles,g] = butter(order,wn,d.kind);
    case 'cheby1', [z,poles,g] = cheby1(order,o.RippleDB,wn,d.kind);
    case 'cheby2', [z,poles,g] = cheby2(order,o.StopDB,wn,d.kind);
    case 'elliptic', [z,poles,g] = ellip(order,o.RippleDB,o.StopDB,wn,d.kind);
    otherwise
        assert(mod(order,2)==0,'Use even FIR order');
        if strcmp(method,'windowed_fir')
            if isnumeric(o.Window)
                w = double(o.Window(:));
                validateattributes(w,{'numeric'},{'numel',order+1,'real','finite'});
            else
                switch validatestring(o.Window,{'hamming','hann','blackman','kaiser'})
                    case 'hamming', w=hamming(order+1);
                    case 'hann', w=hann(order+1);
                    case 'blackman', w=blackman(order+1);
                    case 'kaiser', w=kaiser(order+1,8);
                end
            end
            d.b = fir1(order,wn,d.kind,w);
        else
            tr=o.TransitionHz;
            validateattributes(tr,{'numeric'},{'scalar','real','finite','positive'});
            if strcmp(d.kind,'low')
                f=[0 band(2) band(2)+tr fs/2]; a=[1 1 0 0];
            elseif strcmp(d.kind,'high')
                f=[0 band(1)-tr band(1) fs/2]; a=[0 0 1 1];
            else
                f=[0 band(1)-tr band band(2)+tr fs/2]; a=[0 0 1 1 0 0];
            end
            assert(all(diff(f)>0),'Transition bands must fit strictly inside Nyquist');
            weights=o.Weights;
            if isempty(weights), weights=ones(1,numel(f)/2); end
            validateattributes(weights,{'numeric'},{'vector','numel',numel(f)/2,'real','finite','positive'});
            d.b=firpm(order,f/(fs/2),a,weights);
        end
        assert(all(isfinite(d.b)),'FIR design failed'); return
end
assert(all(abs(poles)<1),'Unstable IIR design');
[d.sos,d.gain]=zp2sos(z,poles,g);
d.form='sos'; d.b=[]; d.a=[];
end

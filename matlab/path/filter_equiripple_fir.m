function d = filter_equiripple_fir(fs, band, order, varargin)
%FILTER_EQUIRIPPLE_FIR Design equiripple_fir coefficients for a frequency interval.
% D = filter_equiripple_fir(FS,[LOW HIGH],ORDER,...) returns a design record.
% See FILTER_DESIGN for options, endpoint behavior and cutoff conventions.
% Apply with FILTER_CAUSAL or FILTER_FORWARD_BACKWARD; no data are read here.
% Example: d=filter_equiripple_fir(500,[4 12],100,'TransitionHz',2);
%          y=filter_forward_backward(randn(5000,1),d);
d=filter_design('equiripple_fir',fs,band,order,varargin{:});
end

function d = filter_chebyshev2(fs, band, order, varargin)
%FILTER_CHEBYSHEV2 Design cheby2 coefficients for a frequency interval.
% D = filter_chebyshev2(FS,[LOW HIGH],ORDER,...) returns a design record.
% See FILTER_DESIGN for options, endpoint behavior and cutoff conventions.
% Apply with FILTER_CAUSAL or FILTER_FORWARD_BACKWARD; no data are read here.
% Example: d=filter_chebyshev2(500,[4 12],4);
%          y=filter_forward_backward(randn(5000,1),d);
d=filter_design('cheby2',fs,band,order,varargin{:});
end

function d = filter_butterworth(fs, band, order, varargin)
%FILTER_BUTTERWORTH Design butterworth coefficients for a frequency interval.
% D = filter_butterworth(FS,[LOW HIGH],ORDER,...) returns a design record.
% See FILTER_DESIGN for options, endpoint behavior and cutoff conventions.
% Apply with FILTER_CAUSAL or FILTER_FORWARD_BACKWARD; no data are read here.
% Example: d=filter_butterworth(500,[4 12],4);
%          y=filter_forward_backward(randn(5000,1),d);
d=filter_design('butterworth',fs,band,order,varargin{:});
end

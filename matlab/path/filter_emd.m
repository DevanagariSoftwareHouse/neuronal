function [imf,residual,info] = filter_emd(x,varargin)
%FILTER_EMD Empirical mode decomposition using MATLAB EMD.
% [IMF,R,INFO] = filter_emd(X,...) forwards EMD name/value parameters.
% X: one vector; IMF: samples-by-modes. Modes are data-derived, not common
% frequency bands across sessions. Requires Signal Processing Toolbox EMD.
% Example: [imf,r]=filter_emd(randn(2000,1),'MaxNumIMF',4);
filter_require('emd');
validateattributes(x,{'numeric'},{'vector','real','finite','nonempty'});
[imf,residual,info]=emd(double(x(:)),varargin{:});
end

function [imf,residual,info] = filter_vmd(x,varargin)
%FILTER_VMD Variational mode decomposition using MATLAB VMD.
% [IMF,R,INFO] = filter_vmd(X,...) forwards VMD name/value parameters.
% Requires MATLAB VMD (introduced R2020a); R2019a raises a dependency error.
% No substitution by EMD and no implicit download of third-party software.
% IMF is samples-by-modes, not a fixed-frequency filter bank.
% Example (R2020a+): [imf,r]=filter_vmd(randn(2000,1),'NumIMFs',4);
filter_require('vmd');
validateattributes(x,{'numeric'},{'vector','real','finite','nonempty'});
[imf,residual,info]=vmd(double(x(:)),varargin{:});
end

function power = filter_power(coefficient)
%FILTER_POWER Squared magnitude of explicit real or complex coefficients.
% P = filter_power(C) computes ABS(C).^2 without smoothing or normalization.
% Units depend on C; this is not automatically PSD/Hz or mean signal power.
% Example: p=filter_power(filter_analytic(y));
validateattributes(coefficient,{'numeric'},{'nonempty'});
power=abs(coefficient).^2;
end

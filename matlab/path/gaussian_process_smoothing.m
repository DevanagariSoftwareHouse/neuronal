function model = gaussian_process_smoothing(activity,times,length_scale,signal_variance,noise_variance)
%GAUSSIAN_PROCESS_SMOOTHING Squared-exponential temporal GP smoother.
% Related mathematical primitive of GPFA (Yu et al. 2009).
% NOT GPFA: no latent-variable factor inference or parameter optimization.
% Dense time-by-time kernel; cap at 2000 bins for exploratory use.
%
%   SYNTAX
%     model = gaussian_process_smoothing(activity,times,length_scale,signal_variance,noise_variance)
%
%   INPUTS
%     activity: Finite time-by-feature matrix, 3 to 2000 rows.
%     times: Strictly increasing finite vector, one value per row.
%     length_scale: Positive kernel time scale, same units as times.
%     signal_variance: Positive kernel variance in squared activity units.
%     noise_variance: Positive observation-noise variance in squared activity units.
%
%   OUTPUTS
%     model: Struct with smoothed (same size as activity), times (column) and mean (per
%       feature).
%
%   EXAMPLE
%     t = (0:99)'*0.02; x = sin(2*pi*t)+0.2*randn(100,1);
%     model = gaussian_process_smoothing(x,t,0.1,1,0.04);
%     % Hyperparameters are supplied, not fitted by this function.
%
x=double(activity); t=double(times(:)); [n,~]=size(x);
assert(n>=3 && n<=2000 && numel(t)==n && all(diff(t)>0));
assert(all(isfinite(x(:))) && all(isfinite(t)));
assert(length_scale>0 && signal_variance>0 && noise_variance>0);
dist=bsxfun(@minus,t,t').^2;
K=signal_variance*exp(-dist/(2*length_scale^2));
mu=mean(x,1);
xc=bsxfun(@minus,x,mu);
L=chol(K+noise_variance*eye(n),'lower');
weights=L'\(L\xc);
model.smoothed=bsxfun(@plus,K*weights,mu);
model.times=t;
model.mean=mu;
end

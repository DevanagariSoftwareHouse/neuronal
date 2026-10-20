function [mean_imfs,mean_residual] = ensemble_empirical_mode_decomposition(signal,ensemble_size,noise_fraction,max_imfs)
%ENSEMBLE_EMPIRICAL_MODE_DECOMPOSITION Exploratory noise-assisted EEMD.
% This aligns modes by extraction index, averaging zeros for missing modes.
% Mode mixing, endpoint artifacts and stopping-rule bias need inspection.
% Use caller-controlled random seed; finite memory: size(signal)*max_imfs.
%
%   SIGNATURE DESCRIPTION
%     signal — sampled signal; units and sample axis are given in the notes above.
%     ensemble_size — the ensemble size value; expected shape, units, and constraints are stated in the notes above.
%     noise_fraction — the noise fraction value; expected shape, units, and constraints are stated in the notes above.
%     max_imfs — the max imfs value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     mean_imfs — the returned value; see the summary above for meaning and units.
%     mean_residual — the returned value; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     [mean_imfs, mean_residual] = ensemble_empirical_mode_decomposition(signal, ensemble_size, noise_fraction, max_imfs);
%
if nargin<2 || isempty(ensemble_size), ensemble_size=20; end
if nargin<3 || isempty(noise_fraction), noise_fraction=.2; end
if nargin<4 || isempty(max_imfs), max_imfs=5; end
x=double(signal(:));
assert(all(isfinite(x)) && ensemble_size>=2 && ...
    noise_fraction>=0 && max_imfs>=1);
sigma=std(x);
mean_imfs=zeros(numel(x),max_imfs);
for i=1:ensemble_size
    noisy=x+noise_fraction*sigma*randn(size(x));
    [imfs,~]=empirical_mode_decomposition(noisy,max_imfs);
    mean_imfs(:,1:size(imfs,2))=mean_imfs(:,1:size(imfs,2))+imfs;
end
mean_imfs=mean_imfs/ensemble_size;
mean_residual=x-sum(mean_imfs,2);
end

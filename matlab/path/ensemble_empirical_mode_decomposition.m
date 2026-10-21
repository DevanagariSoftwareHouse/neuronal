function [mean_imfs,mean_residual] = ensemble_empirical_mode_decomposition(signal,ensemble_size,noise_fraction,max_imfs)
%ENSEMBLE_EMPIRICAL_MODE_DECOMPOSITION Exploratory noise-assisted EEMD.
% This aligns modes by extraction index, averaging zeros for missing modes.
% Mode mixing, endpoint artifacts and stopping-rule bias need inspection.
% Use caller-controlled random seed; finite memory: size(signal)*max_imfs.
%
%   SYNTAX
%     [mean_imfs,mean_residual] = ensemble_empirical_mode_decomposition(signal,ensemble_size,noise_fraction,max_imfs)
%
%   INPUTS
%     signal: Finite vector suitable for empirical_mode_decomposition (>=16 samples).
%     ensemble_size: Integer noisy realizations >=2; default 20.
%     noise_fraction: Nonnegative noise SD relative to std(signal); default 0.2.
%     max_imfs: Positive integer number of mode columns; default 5.
%
%   OUTPUTS
%     mean_imfs: Samples-by-max_imfs averaged modes, aligned by extraction index.
%     mean_residual: Samples-by-1 signal minus the sum of averaged modes.
%
%   EXAMPLE
%     fs = 500; t = (0:4999)'/fs;
%     x = sin(2*pi*8*t) + 0.2*randn(size(t));
%     rng(7);
%     [imfs, residual] = ensemble_empirical_mode_decomposition(x,10,0.2,3);
%     % Missing modes contribute zeros; inspect mode alignment across realizations.
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

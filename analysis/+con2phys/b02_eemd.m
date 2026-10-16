clc
clear
a00_startup
%%
catalog = neuronal_catalog()
%%
data = catalog.data;
%%

lfp = neuronal_memmap(data(1).file(1))

%%

y = lfp.Data.x(:,15);
%%
[mean_imfs,mean_residual] = ensemble_empirical_mode_decomposition(y,100,0.01,20);
%%
t = (1:data(1).n_lfp_samples)/500

%%
[P,F] = pwelch(a(:,5),5000,5000/2,2^16,500);
%%
[S,F,T,P,Fc,Tc] = spectrogram(a(:,5),5000,5000/2,2^16,500);
% %
imagesc(T,F,log10(P))
axis xy
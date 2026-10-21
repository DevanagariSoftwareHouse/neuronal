%% Short real-data EMD/EEMD comparison; cap cost and inspect reconstruction.
r=struct('mode','real'); x=c.x(1:min(numel(c.x),round(4*c.fs)));
[r.imfs,r.residual]=empirical_mode_decomposition(x,4,30,.2);
[r.ensemble_imfs,r.ensemble_residual]=ensemble_empirical_mode_decomposition(x,10,.1,4);
r.reconstruction_error=norm(x-sum(r.imfs,2)-r.residual)/max(norm(x),eps);
assert(r.reconstruction_error<1e-8,'EMD reconstruction failed.');
if cfg.plots
    figure('Name','EMD'); plot((0:numel(x)-1)/c.fs,[x r.imfs]); xlabel('s');
end

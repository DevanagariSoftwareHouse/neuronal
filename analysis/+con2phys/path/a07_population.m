%% Population geometry on real time-bin counts (clusters, not certified neurons).
r=struct('mode','real'); X=c.C;
r.pca=population_pca(X,3);
r.dimension=participation_ratio(X);
r.scaling=population_dimension_scaling(X,unique([2 floor(size(X,2)/2) size(X,2)]),10,cfg.seed);
assert(nnz(r.pca.eigenvalues>0)>=3,'battle:skip','Need >=3 positive eigenvalues.');
r.powerlaw=eigenspectrum_powerlaw(r.pca.eigenvalues);
r.assemblies=assembly_pca(X,3);
z=(X-mean(X,1))./std(X,0,1);
r.expression=assembly_expression(z,r.assemblies.templates);
n=min(200,size(X,1));
r.gp=gaussian_process_smoothing(X(1:n,:),(0:n-1)'*.1,.3,1,.5);
r.rotation=jpca_dynamics(r.pca.scores,.1);
% Source/target partitions are cluster subsets, not inferred anatomical pathways.
split=floor(size(X,2)/2); train=1:floor(.7*size(X,1)); test=train(end)+1:size(X,1);
r.rrr=reduced_rank_regression(X(train,1:split),X(train,split+1:end),1,1);
r.heldout_projection=communication_subspace_projection(X(test,1:split),r.rrr);
pred=(X(test,1:split)-r.rrr.source_mean)*r.rrr.coefficients+r.rrr.target_mean;
r.heldout_mse=mean((pred-X(test,split+1:end)).^2,1);
w=corrcoef(X); w(~isfinite(w))=0; w=max(w,0); w(1:size(w,1)+1:end)=0;
r.modularity=greedy_modularity(w);
if cfg.plots
    figure('Name','Population'); plot(r.pca.scores(:,1:3)); xlabel('100-ms bin'); ylabel('PC score');
end

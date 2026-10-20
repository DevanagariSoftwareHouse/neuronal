%% Lagged predictive dependence of spike counts; not synaptic/physical causality.
r=struct('mode','real'); X=c.C(:,1:min(4,size(c.C,2)));
r.granger=granger_causality(X,1,2,3);
r.reverse=granger_causality(X,2,1,3);
r.te=transfer_entropy(X(:,1)>0,X(:,2)>0);
r.mi=mutual_information(X(:,1)>0,X(:,2)>0);
[design,valid]=spike_history_design(X,3);
r.glm=poisson_spike_glm(design,X(valid,1),.1,1,50);
r.coupling=coupling_filters(X,3,.1,1);
r.lag_sensitivity=sensitivity_analysis({1,2,3,5},@(lag)transfer_entropy(X(1:lag:end,1)>0,X(1:lag:end,2)>0));

function projection = communication_subspace_projection(activity,model)
%COMMUNICATION_SUBSPACE_PROJECTION Coordinates of predictive source axes.
% Semedo et al. (2019); model from reduced_rank_regression on training.
%
%   SYNTAX
%     projection = communication_subspace_projection(activity,model)
%
%   INPUTS
%     activity: Finite observations-by-source-units matrix in fitted unit order.
%     model: Struct returned by reduced_rank_regression; uses source_mean and source_axes.
%
%   OUTPUTS
%     projection: Observations-by-retained-rank centered source coordinates.
%
%   EXAMPLE
%     x = randn(60,4); y = x(:,1:2)+0.2*randn(60,2);
%     model = reduced_rank_regression(x,y,2,1);
%     projection = communication_subspace_projection(x,model);
%     % For evaluation, project held-out activity using a training-only model.
%
x=double(activity);
assert(size(x,2)==numel(model.source_mean) && all(isfinite(x(:))));
projection=bsxfun(@minus,x,model.source_mean)*model.source_axes;
end

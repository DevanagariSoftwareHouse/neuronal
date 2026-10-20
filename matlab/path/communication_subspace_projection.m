function projection = communication_subspace_projection(activity,model)
%COMMUNICATION_SUBSPACE_PROJECTION Coordinates of predictive source axes.
% Semedo et al. (2019); model from reduced_rank_regression on training.
%
%   SIGNATURE DESCRIPTION
%     activity — neural activity matrix; observation/time rows and unit columns unless noted.
%     model — the model value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     projection — the returned projection; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     projection = communication_subspace_projection(activity, model);
%
x=double(activity);
assert(size(x,2)==numel(model.source_mean) && all(isfinite(x(:))));
projection=bsxfun(@minus,x,model.source_mean)*model.source_axes;
end

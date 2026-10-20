function shuffled = trial_shuffle_surrogate(trials)
%TRIAL_SHUFFLE_SURROGATE Permute trial identities of one variable.
% trials: cell array with one spike train or signal per trial.
% Use independently from the other variable in a cross-trial null.
%
%   SIGNATURE DESCRIPTION
%     trials — the trials value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     shuffled — the returned shuffled; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     shuffled = trial_shuffle_surrogate(trials);
%
assert(iscell(trials)&&numel(trials)>=2);
shuffled=trials(randperm(numel(trials)));
end

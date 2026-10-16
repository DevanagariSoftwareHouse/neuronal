function shuffled = trial_shuffle_surrogate(trials)
%TRIAL_SHUFFLE_SURROGATE Permute trial identities of one variable.
% trials: cell array with one spike train or signal per trial.
% Use independently from the other variable in a cross-trial null.
assert(iscell(trials)&&numel(trials)>=2);
shuffled=trials(randperm(numel(trials)));
end

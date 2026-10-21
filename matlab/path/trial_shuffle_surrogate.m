function shuffled = trial_shuffle_surrogate(trials)
%TRIAL_SHUFFLE_SURROGATE Permute trial identities of one variable.
% trials: cell array with one spike train or signal per trial.
% Use independently from the other variable in a cross-trial null.
%
%   SYNTAX
%     shuffled = trial_shuffle_surrogate(trials)
%
%   INPUTS
%     trials: Cell array with >=2 entries, each holding one trial signal or spike train.
%
%   OUTPUTS
%     shuffled: Cell array containing a random permutation of trial entries; within-trial
%       content unchanged.
%
%   EXAMPLE
%     rng(7); trials = {[0.1 0.2],[0.3],[0.2 0.5]};
%     shuffled = trial_shuffle_surrogate(trials);
%     % Shuffle one variable independently of its paired trial variable.
%
assert(iscell(trials)&&numel(trials)>=2);
shuffled=trials(randperm(numel(trials)));
end

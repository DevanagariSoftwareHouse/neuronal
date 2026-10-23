function value = questionnaire_trial_participation(indices,trials)
%QUESTIONNAIRE_TRIAL_PARTICIPATION Recompute covariance PR of whole trials.
% indices: resampled trial IDs; trials: cell of time-bin x fixed-unit matrices.
x=vertcat(trials{indices(:)});
value=participation_ratio(x);
end

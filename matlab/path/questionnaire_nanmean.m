function value = questionnaire_nanmean(indices,values,minimum)
%QUESTIONNAIRE_NANMEAN Mean over finite observations at resampled row IDs.
% Missing positions remain in the time index; no temporal gaps are closed.
x=values(indices); x=x(isfinite(x));
if numel(x)<minimum
    error('questionnaire:InsufficientFiniteRows', ...
        'A replicate contains fewer than %d finite observations.',minimum);
end
value=mean(x);
end

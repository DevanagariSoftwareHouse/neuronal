function x = trial_features(spikes,windows)
%TRIAL_FEATURES Trial x unit firing rates inside explicit time windows.
% X = TRIAL_FEATURES(SPIKES, WINDOWS) with SPIKES a cell array of
% timestamp vectors (seconds), one per unit, and WINDOWS an N x 2 matrix
% [start stop] in seconds, returns N x units rates in spikes/s.
% Windows are half-open [start,stop). Rows with a nonfinite or
% nonpositive-length window are NaN.
% See also spike_bins, decode_trials, peri_event_histogram.
    x=nan(size(windows,1),numel(spikes));
    for k=1:size(windows,1)
        if any(~isfinite(windows(k,:))) || diff(windows(k,:))<=0, continue; end
        for u=1:numel(spikes)
            x(k,u)=sum(spikes{u}>=windows(k,1) & spikes{u}<windows(k,2))/diff(windows(k,:));
        end
    end
end

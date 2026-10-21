function x = trial_features(spikes,windows)
%TRIAL_FEATURES Per-trial firing rates for multiple spike trains.
%
%   SYNTAX
%     x = trial_features(spikes,windows)
%
%   INPUTS
%     spikes: Cell array of unit spike-time vectors in seconds; use vectors, not matrices.
%     windows: Trials-by-2 [start stop] seconds; nonfinite or nonpositive windows yield NaN
%       rows.
%
%   OUTPUTS
%     x: Trials-by-units firing rates in spikes/s using half-open windows.
%
%   EXAMPLE
%     spikes = {[0.1 0.4 1.2], [0.2 1.4 1.8]}; windows = [0 1;1 2];
%     x = trial_features(spikes,windows);
%     % x=[2 1;1 2] spikes/s for these one-second windows.
%
    x=nan(size(windows,1),numel(spikes));
    for k=1:size(windows,1)
        if any(~isfinite(windows(k,:))) || diff(windows(k,:))<=0, continue; end
        for u=1:numel(spikes)
            x(k,u)=sum(spikes{u}>=windows(k,1) & spikes{u}<windows(k,2))/diff(windows(k,:));
        end
    end
end

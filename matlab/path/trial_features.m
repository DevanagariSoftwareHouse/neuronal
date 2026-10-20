function x = trial_features(spikes,windows)
%
%   SIGNATURE DESCRIPTION
%     spikes — the spikes value; expected shape, units, and constraints are stated in the notes above.
%     windows — the windows value; expected shape, units, and constraints are stated in the notes above.
%   RETURNS
%     x — the returned x; see the summary above for meaning and units.
%   USAGE EXAMPLE
%     % Prepare the input variables above with the documented dimensions and units.
%     x = trial_features(spikes, windows);
%
    x=nan(size(windows,1),numel(spikes));
    for k=1:size(windows,1)
        if any(~isfinite(windows(k,:))) || diff(windows(k,:))<=0, continue; end
        for u=1:numel(spikes)
            x(k,u)=sum(spikes{u}>=windows(k,1) & spikes{u}<windows(k,2))/diff(windows(k,:));
        end
    end
end

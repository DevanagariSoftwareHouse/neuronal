function times_s = phase_crossing_events(phase_rad, srate, target_phase_rad, min_separation_s)
%PHASE_CROSSING_EVENTS Detect forward crossings of an oscillatory phase.
% TIMES = PHASE_CROSSING_EVENTS(PHASE, FS, TARGET, MIN_SEPARATION_S)
% PHASE may be wrapped (-pi..pi) or unwrapped, in radians. Forward
% crossings through TARGET (mod 2*pi) are linearly interpolated between
% adjacent samples; timestamps use sample 1 = 0 seconds.
% PHASE should come from an appropriately bandpassed analytic signal.
% Sampling must resolve phase changes (< pi radians per sample).
if nargin < 3 || isempty(target_phase_rad), target_phase_rad = 0; end
if nargin < 4 || isempty(min_separation_s), min_separation_s = 0; end
validateattributes(phase_rad, {'numeric'}, {'vector','real','finite'});
validateattributes(srate, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(target_phase_rad, {'numeric'}, {'scalar','real','finite'});
validateattributes(min_separation_s, {'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
ph = double(phase_rad(:));
if numel(ph) < 2
    times_s = zeros(0,1);
    return
end
relative = angle(exp(1i * (ph - double(target_phase_rad))));
step = diff(relative);
crossings = find(relative(1:end-1) < 0 & relative(2:end) >= 0 ...
    & step > 0 & step < pi);
times_s = (double(crossings)-1 - relative(crossings)./step(crossings)) ...
    / double(srate);

if min_separation_s > 0 && ~isempty(times_s)
    keep = false(size(times_s));
    last = -inf;
    for k = 1:numel(times_s)
        if times_s(k) - last >= min_separation_s
            keep(k) = true;
            last = times_s(k);
        end
    end
    times_s = times_s(keep);
end
end

function nodes = interval_renewal(N, fs, durations_s)
%INTERVAL_RENEWAL Generate renewal intervals from supplied positive waiting times.
% nodes = interval_renewal(N, fs, durations_s)
% Cumulative durations start at zero and are clipped to the session.
% Supply iid draws from any positive waiting-time law for a renewal model.
% If draws end before T the uncovered tail is NOT fabricated.
% Example: w = interval_renewal(1000,500,[.2 .3 .7 1]);

interval_session(N,fs);
validateattributes(durations_s, {'numeric'}, {'2d','real','finite','positive'});
assert(isvector(durations_s) || isempty(durations_s), 'interval:Shape', 'Expected a vector.');
edges = [0;cumsum(double(durations_s(:)))];
assert(all(isfinite(edges)), 'interval:Data', 'Waiting time accumulation overflow.');
nodes = interval_from_bounds(N,fs,[edges(1:end-1),edges(2:end)]);
end

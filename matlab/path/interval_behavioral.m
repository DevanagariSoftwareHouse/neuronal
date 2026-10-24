function nodes = interval_behavioral(N, fs, starts_s, stops_s)
%INTERVAL_BEHAVIORAL Generate intervals from paired behavioral or trial boundaries.
% nodes = interval_behavioral(N, fs, starts_s, stops_s)
% Preserves row order and overlap; clips to session. source_index maps to
% the original trial, even when outside or zero-duration trials are dropped.
% Example: w = interval_behavioral(1000,500,[0 .8],[.5 1.5]);

validateattributes(starts_s, {'numeric'}, {'2d','real','finite'});
assert(isvector(starts_s) || isempty(starts_s), 'interval:Shape', 'Expected a vector.');
validateattributes(stops_s, {'numeric'}, {'2d','real','finite','numel',numel(starts_s)});
assert(isvector(stops_s) || isempty(stops_s), 'interval:Shape', 'Expected a vector.');
nodes = interval_from_bounds(N,fs,[double(starts_s(:)),double(stops_s(:))]);
end

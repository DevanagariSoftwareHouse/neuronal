function nodes = interval_event(N, fs, events_s, pre_s, post_s)
%INTERVAL_EVENT Generate windows around event times.
% nodes = interval_event(N, fs, events_s, pre_s, post_s)
% Nonnegative pre/post durations in seconds define [event-pre,event+post).
% Clips to session; source_index maps surviving windows to input events.
% Example: w = interval_event(1000,500,[0 .5 1.9],.1,.2);

validateattributes(events_s, {'numeric'}, {'2d','real','finite'});
assert(isvector(events_s) || isempty(events_s), 'interval:Shape', 'Expected a vector.');
validateattributes(pre_s, {'numeric'}, {'scalar','real','finite','nonnegative'});
validateattributes(post_s, {'numeric'}, {'scalar','real','finite','nonnegative'});
assert(pre_s+post_s>0, 'interval:Width', 'Event window must have positive width.');
e = double(events_s(:));
nodes = interval_from_bounds(N,fs,[e-double(pre_s),e+double(post_s)]);
end

function node = interval_geometric(N, fs, first_width_s, ratio, k)
%INTERVAL_GEOMETRIC Lazily generate contiguous geometrically growing intervals.
% node = interval_geometric(N, fs, first_width_s, ratio, k)
% Widths are first_width_s * ratio^(k-1), ratio >= 1. Final interval is
% clipped to the session end. Ratio=1 includes a final partial interval.
% Example: w = interval_geometric(1000,500,.1,2,3);

T = interval_session(N,fs);
validateattributes(first_width_s, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(ratio, {'numeric'}, {'scalar','real','finite','>=',1});
validateattributes(k, {'numeric'}, {'scalar','real','finite','integer','positive'});
a = double(first_width_s); r = double(ratio); k = double(k);
if r == 1
    count = T/a;
    t0 = (k-1)*a;
    t1 = k*a;
else
    count = log1p((T/a)*(r-1))/log(r);
    t0 = a*expm1((k-1)*log(r))/(r-1);
    t1 = a*expm1(k*log(r))/(r-1);
end
assert(isfinite(count) && count < flintmax, 'interval:Resolution', 'Unrepresentable interval count.');
n = max(1,ceil(count-8*eps(max(1,count))));
assert(k <= n, 'interval:Index', 'Window index exceeds available intervals.');
node = interval_from_bounds(N,fs,[t0,min(T,t1)]);
assert(~isempty(node), 'interval:Resolution', 'Window is below time precision.');
node.window = k; node.source_index = k; node.n_windows = n;
node.ratio = r;
end

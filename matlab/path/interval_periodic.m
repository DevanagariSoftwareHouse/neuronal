function node = interval_periodic(N, fs, frequency_hz, phase_rad, duty, k)
%INTERVAL_PERIODIC Lazily generate a positive run of a periodic square wave.
% node = interval_periodic(N, fs, frequency_hz, phase_rad, duty, k)
% Selects phase mod 2*pi in [0,2*pi*duty), duty in (0,1]. Includes
% clipped runs at both session edges. Phase is normalized to [0,2*pi).
% At duty=1 each period remains a separate interval. No square() needed.
% Example: w = interval_periodic(1000,500,1,-pi/2,.5,1);

T = interval_session(N,fs);
validateattributes(frequency_hz, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(phase_rad, {'numeric'}, {'scalar','real','finite'});
validateattributes(duty, {'numeric'}, {'scalar','real','finite','>',0,'<=',1});
validateattributes(k, {'numeric'}, {'scalar','real','finite','integer','positive'});
f = double(frequency_hz); duty = double(duty);
p = mod(double(phase_rad),2*pi)/(2*pi);
% Cycle m has bounds [(m-p)/f,(m-p+duty)/f).
m0 = floor(p-duty)+1;
m1 = ceil(f*T+p)-1;
n = max(0,m1-m0+1);
assert(isfinite(n) && n < flintmax, 'interval:Resolution', 'Too many cycles.');
assert(k <= n, 'interval:Index', 'Window index exceeds positive runs.');
m = m0+double(k)-1;
node = interval_from_bounds(N,fs,[(m-p)/f,(m-p+duty)/f]);
assert(~isempty(node), 'interval:Resolution', 'Run is below time precision.');
node.window = double(k); node.source_index = double(k); node.n_windows = n;
node.frequency_hz = f; node.phase_rad = p*2*pi; node.duty = duty;
node.cycle = m;
end

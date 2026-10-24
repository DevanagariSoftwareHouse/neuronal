function T = interval_session(N, fs)
%INTERVAL_SESSION Validate the common sampled session.

validateattributes(N, {'numeric'}, {'scalar','real','finite','integer','positive','<=',flintmax});
validateattributes(fs, {'numeric'}, {'scalar','real','finite','positive'});
T = double(N)/double(fs);
assert(isfinite(T) && T > 0, 'interval:Session', 'Session duration must be finite and positive.');
end

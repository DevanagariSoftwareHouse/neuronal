function nodes = interval_adaptive(N, fs, mass, target)
%INTERVAL_ADAPTIVE Partition samples by accumulated nonnegative mass.
% nodes = interval_adaptive(N, fs, mass, target)
% mass has N nonnegative finite sample weights (e.g. abs(lfp).^2/fs for
% energy). Close each block after reaching target and retain the tail.
% Overshoot remains in that block; zero-mass data yields the whole session.
% O(N) scan; interval duration adapts to mass, without a stationarity claim.
% Example: w = interval_adaptive(6,10,[0 2 1 0 4 0],3);

interval_session(N,fs);
validateattributes(mass, {'numeric'}, {'vector','numel',double(N),'real','finite','nonnegative'});
validateattributes(target, {'numeric'}, {'scalar','real','finite','positive'});
bounds = zeros(0,2); start = 1; total = 0;
for i = 1:double(N)
    total = total+double(mass(i));
    if total >= double(target)
        bounds(end+1,:) = [(start-1)/double(fs),i/double(fs)]; %#ok<AGROW>
        start = i+1; total = 0;
    end
end
if start <= double(N)
    bounds(end+1,:) = [(start-1)/double(fs),double(N)/double(fs)];
end
nodes = interval_from_bounds(N,fs,bounds);
end

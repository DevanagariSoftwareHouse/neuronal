function nodes = interval_changepoint(N, fs, x, penalty, min_samples)
%INTERVAL_CHANGEPOINT Partition by greedy binary segmentation of changes in mean.
% nodes = interval_changepoint(N, fs, x, penalty, min_samples)
% Splits each segment at the largest reduction of within-segment SSE if
% reduction > penalty; each child has at least min_samples (default 2).
% Penalty has units of squared signal amplitude. This is greedy, not
% globally optimal penalized segmentation and not a significance test.
% Finite vector required. Worst-case O(N^2) time, O(N) workspace.
% Example: w = interval_changepoint(20,10,[zeros(1,10) ones(1,10)],1,2);

if nargin < 5, min_samples = 2; end
interval_session(N,fs);
validateattributes(x, {'numeric'}, {'vector','numel',double(N),'real','finite'});
validateattributes(penalty, {'numeric'}, {'scalar','real','finite','nonnegative'});
validateattributes(min_samples, {'numeric'}, {'scalar','real','finite','integer','positive'});
x = double(x(:)); x = x-mean(x);
s = [0;cumsum(x)];
assert(all(isfinite(s)), 'interval:Data', 'Cumulative signal overflow.');
pending = [1,double(N)]; result = zeros(0,2);
while ~isempty(pending)
    a = pending(end,1); b = pending(end,2); pending(end,:) = [];
    cuts = (a+double(min_samples)-1:b-double(min_samples)).';
    if isempty(cuts)
        result(end+1,:) = [a,b]; %#ok<AGROW>
        continue
    end
    nl = cuts-a+1; nr = b-cuts;
    ml = (s(cuts+1)-s(a))./nl;
    mr = (s(b+1)-s(cuts+1))./nr;
    gain = (nl.*nr/(b-a+1)).*(ml-mr).^2;
    assert(all(isfinite(gain)), 'interval:Data', 'SSE gain overflow.');
    [best,j] = max(gain);
    if best > double(penalty)
        c = cuts(j); pending = [pending;a,c;c+1,b]; %#ok<AGROW>
    else
        result(end+1,:) = [a,b]; %#ok<AGROW>
    end
end
result = sortrows(result,1);
nodes = interval_from_bounds(N,fs,[(result(:,1)-1)/double(fs),result(:,2)/double(fs)]);
end

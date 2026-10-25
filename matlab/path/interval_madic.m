function node = interval_madic(N, fs, base, level, overlap, k)
%INTERVAL_MADIC Lazily generate one or more m-adic interval banks.
% node = interval_madic(N, fs, base, level, overlap, k)
% Width = (N/fs)/base^level; hop = width*(1-overlap). Base >= 2.
% level and overlap may be vectors. Their Cartesian product is generated in
% level-major order, with overlap varying fastest. Use k='all' to return the
% combined bank; each record retains its level and overlap fields. Count and
% indexed queries continue to use the scalar API (for vectors, count returns
% the total and k indexes the concatenated bank).
% With overlap=0 the levels form a nested tree; with overlap>0 they form
% a multiscale cover, without a unique parent for every window.
% Example: w = interval_madic(3000,500,3,2,.5,4);
% Omit final k (or pass []) to return the number of complete/available windows.
% Counting uses O(1) memory and does not build an interval bank.
% Pass 'all' as final k to return a column struct array of every window.
% Bulk output uses O(number of windows) memory; no sample masks are created.

if nargin < 6, k = []; end
T = interval_session(N,fs);
validateattributes(base, {'numeric'}, {'scalar','real','finite','integer','>=',2});
validateattributes(level, {'numeric'}, {'vector','real','finite','integer','nonnegative'});
validateattributes(overlap, {'numeric'}, {'vector','real','finite','>=',0,'<',1});
assert(~isempty(level) && ~isempty(overlap), 'interval:Parameters', ...
    'level and overlap must be nonempty numeric vectors.');

% Keep the established scalar path and its count/index behavior.
if isscalar(level) && isscalar(overlap)
    if ischar(k) && isequal(k,'all')
        node = interval_collect(@interval_madic,{N,fs,base,level,overlap});
        return
    end
    node = interval_madic_scalar(N,fs,base,level,overlap,k,T);
    return
end

% Vector-valued parameters form a concatenated bank. Numeric k is a global
% 1-based index into that bank; [] returns its total number of windows.
if ~(isempty(k) || (ischar(k) && isequal(k,'all')))
    validateattributes(k, {'numeric'}, {'scalar','real','finite','integer','positive'});
end
total = 0;
for li = 1:numel(level)
    for oi = 1:numel(overlap)
        count = interval_madic_scalar(N,fs,base,level(li),overlap(oi),[],T);
        if isempty(k)
            total = total + count;
        elseif isnumeric(k) && k > total && k <= total + count
            node = interval_madic_scalar(N,fs,base,level(li),overlap(oi),k-total,T);
            return
        elseif isnumeric(k)
            total = total + count;
        end
    end
end
if isempty(k)
    node = total;
    return
elseif isnumeric(k)
    assert(k <= total, 'interval:Index', 'Window index exceeds available intervals.');
    return
end

% Materialize the product only when the caller explicitly requests 'all'.
node = struct([]);
has_nodes = false;
for li = 1:numel(level)
    for oi = 1:numel(overlap)
        count = interval_madic_scalar(N,fs,base,level(li),overlap(oi),[],T);
        if count == 0, continue; end
        first = interval_madic_scalar(N,fs,base,level(li),overlap(oi),1,T);
        part = repmat(first,count,1);
        for wi = 2:count
            part(wi) = interval_madic_scalar( ...
                N,fs,base,level(li),overlap(oi),wi,T);
        end
        if has_nodes
            node = [node; part(:)]; %#ok<AGROW>
        else
            node = part(:);
            has_nodes = true;
        end
    end
end
end

function node = interval_madic_scalar(N,fs,base,level,overlap,k,T)
validateattributes(level, {'numeric'}, {'scalar','real','finite','integer','nonnegative'});
validateattributes(overlap, {'numeric'}, {'scalar','real','finite','>=',0,'<',1});
parts = double(base)^double(level);
assert(isfinite(parts) && parts <= double(N), 'interval:Resolution', ...
    'Nominal width must be at least one sample.');
width = T/parts;
node = interval_sliding(N,fs,width,width*(1-double(overlap)),k);
if isempty(k), return; end
node.base = double(base); node.level = double(level); node.overlap = double(overlap);
node.frequency_hz = 1/(2*width);
node.phase_rad = mod(-2*pi*node.frequency_hz*node.t0,2*pi);
node.phase_step_rad = pi*(1-double(overlap));
end

function nodes = interval_collect(generator, args)
%INTERVAL_COLLECT Materialize a lazy generator using its count/index API.
n = generator(args{:});
if n == 0
    nodes = struct([]);
    return
end
first = generator(args{:},1);
nodes = repmat(first,n,1);
for j = 2:n
    nodes(j) = generator(args{:},j);
end
end

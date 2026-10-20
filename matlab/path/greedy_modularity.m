function best=greedy_modularity(w)
%GREEDY_MODULARITY Best weighted modularity Q from greedy community merging.
% Q = GREEDY_MODULARITY(W) starts from singleton communities of the
% symmetric nonnegative weight matrix W (e.g. unit correlations clipped at
% zero) and repeatedly merges the pair of communities with the largest
% positive gain in Q = sum_ij (W_ij - k_i k_j / s) delta(c_i,c_j) / s.
% Returns NaN when the total weight s is not positive.
% Heuristic: a local optimum, not the maximal modularity; assignments are
% not returned. O(n^2) pair search per merge; keep W small.
% See also noise_correlation, assembly_pca.
    s=sum(w(:)); best=nan; if s<=0, return; end
    k=sum(w,2); b=w-k*k'/s; group=1:size(w,1);
    best=sum(diag(b))/s;
    while true
        labels=unique(group); gain=0; pair=[];
        for i=1:numel(labels)
            for j=i+1:numel(labels)
                delta=2*sum(sum(b(group==labels(i),group==labels(j))))/s;
                if delta>gain+1e-12, gain=delta; pair=[labels(i) labels(j)]; end
            end
        end
        if isempty(pair), break; end
        group(group==pair(2))=pair(1); best=best+gain;
    end
end

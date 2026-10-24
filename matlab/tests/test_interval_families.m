%% Regression and invariant checks for interval generators (base MATLAB only).
interval_test_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(interval_test_dir,'..','path'));

% Direct conversion: clipping, source rows, exact grid edges, empty results.
w = interval_from_bounds(10,10,[-1 .2; .3 .6; 2 3; .8 .8]);
assert(isequal([w.first],[1 4]) && isequal([w.last],[2 6]));
assert(isequal([w.source_index],[1 2]));
assert(isempty(interval_from_bounds(10,10,zeros(0,2))));
w = interval_from_bounds(10,10,[.01 .02]);
assert(w.n_samples==0 && isempty(w.first:w.last));

% Exhaustive small odd/even partitions: coverage once and lazy consistency.
for N = [7 16 101]
    for parts = 1:N
        seen = zeros(1,N);
        for k = 1:parts
            w = interval_uniform(N,10,parts,k);
            seen(w.first:w.last) = seen(w.first:w.last)+1;
            assert(w.n_windows==parts);
        end
        assert(all(seen==1));
    end
end
for base = [2 3 5]
    for level = 0:2
        for overlap = [0 .25 .5 .75]
            first_node = interval_madic(1001,500,base,level,overlap,1);
            for k = 1:first_node.n_windows
                w = interval_madic(1001,500,base,level,overlap,k);
                assert(w.first>=1 && w.last<=1001 && w.n_samples>0);
                assert(abs(w.duration_s-1001/500/base^level)<1e-12);
            end
        end
    end
end
a = interval_at(1000,500,1,.5,1); b = interval_at(1000,500,1,.5,2);
assert(numel(intersect(a.first:a.last,b.first:b.last))==250);
assert(abs(max(0,min(a.t1,b.t1)-max(a.t0,b.t0))/a.duration_s-.5)<1e-12);
w = interval_sliding(100,10,2,3,3);
assert(w.first==61 && w.last==80 && w.n_windows==3 && w.overlap==0);

% Geometric partitions include final partial windows.
for ratio = [1 1+1e-8 1.5 2]
    w = interval_geometric(100,10,1,ratio,1);
    seen = zeros(1,100);
    for k = 1:w.n_windows
        g = interval_geometric(100,10,1,ratio,k);
        seen(g.first:g.last) = seen(g.first:g.last)+1;
    end
    assert(all(seen==1));
end
w = interval_geometric(100,10,20,2,1);
assert(w.first==1 && w.last==100 && w.n_windows==1);

% Periodic runs match an independent modular-phase predicate off transitions.
t = (0:999)/100;
for phase = [0 -pi/2 pi/3 2*pi]
    for duty = [.25 .5 1]
        f = .7; w = interval_periodic(1000,100,f,phase,duty,1);
        selected = false(size(t));
        for k = 1:w.n_windows
            z = interval_periodic(1000,100,f,phase,duty,k);
            selected(z.first:z.last) = true;
        end
        q = mod(f*t+phase/(2*pi),1);
        away = abs(q-duty)>1e-10 & q>1e-10 & q<1-1e-10;
        assert(isequal(selected(away),q(away)<duty));
    end
end
w = interval_periodic(100,10,.05,0,.5,1); % whole session positive
assert(w.first==1 && w.last==100);
w = interval_wavelet(100,10,[-3 3],.5,1);
assert(w.t0==0 && w.t1==2.5 && w.last==25);
assert(isempty(interval_wavelet(100,10,[-1 1],1,20)));

% Events and behavioral rows preserve source identity through clipping.
w = interval_event(100,10,[-10 0 9.9],.2,.3);
assert(isequal([w.source_index],[2 3]) && w(1).first==1 && w(2).last==100);
w = interval_between_events(100,10,[1 1 3 11]);
assert(isequal([w.source_index],[2 3]) && w(end).t1==10);
w = interval_behavioral(100,10,[-2 1 11],[-1 3 12]);
assert(numel(w)==1 && w.source_index==2 && w.first==11 && w.last==30);
assert(isempty(interval_event(100,10,[],1,1)));
assert(isempty(interval_between_events(100,10,[])));
assert(isempty(interval_behavioral(100,10,[],[])));

% Quantile ties collapse borders, while retaining full temporal coverage.
w = interval_quantile(100,10,[1 2 3 4],2);
assert(numel(w)==2 && w(1).t1==2.5 && w(2).first==26);
w = interval_quantile(100,10,[2 2 2 2],4);
assert(numel(w)==2 && w(1).first==1 && w(end).last==100);
w = interval_quantile(100,10,2,1);
assert(numel(w)==1 && w.first==1 && w.last==100);

% Excursions break at NaN; accumulated mass closes on the crossing sample.
w = interval_threshold(7,10,[0 2 3 NaN 4 0 5],1,0);
assert(isequal([w.first],[2 5 7]) && isequal([w.last],[3 5 7]));
w = interval_threshold(7,10,[0 2 3 NaN 4 0 5],1,.15);
assert(numel(w)==1 && w.first==2 && w.last==3);
assert(isempty(interval_threshold(3,10,zeros(1,3),1)));
w = interval_adaptive(6,10,[0 2 1 0 4 0],3);
assert(isequal([w.first],[1 4 6]) && isequal([w.last],[3 5 6]));
w = interval_adaptive(6,10,zeros(1,6),1);
assert(numel(w)==1 && w.n_samples==6);
w = interval_changepoint(20,10,[zeros(1,10) ones(1,10)],1,2);
assert(isequal([w.first],[1 11]) && isequal([w.last],[10 20]));
w = interval_changepoint(20,10,ones(1,20),0,2);
assert(numel(w)==1 && w.n_samples==20);

% Random generators are reproducible and do not consume caller RNG state.
rng(123); state_before = rng;
a = interval_stochastic(1000,100,20,[.1 .5],42);
assert(isequal(rng,state_before));
b = interval_stochastic(1000,100,20,[.1 .5],42);
assert(isequal(a,b) && all([a.t0]>=0) && all([a.t1]<=10));
assert(all([a.duration_s]>=.1-1e-12 & [a.duration_s]<=.5+1e-12));
assert(isempty(interval_stochastic(1000,100,0,[.1 .5],42)));
a = interval_poisson(1000,100,5,42);
assert(isequal(rng,state_before));
b = interval_poisson(1000,100,5,42);
assert(isequal(a,b) && a(1).t0==0 && a(end).t1==10);
assert(all([a(1:end-1).t1]==[a(2:end).t0]));
w = interval_renewal(100,10,[1 2 20]);
assert(isequal([w.t0],[0 1 3]) && isequal([w.t1],[1 3 10]));
w = interval_renewal(100,10,[1 2]);
assert(w(end).t1==3);
assert(isempty(interval_renewal(100,10,[])));

% Invalid inputs must fail before returning misleading intervals.
bad_calls = {@() interval_at(10,10,4,0,1), ...
    @() interval_madic(100,10,1,1,0,1), ...
    @() interval_sliding(100,10,1,0,1), ...
    @() interval_uniform(100,10,2,3), ...
    @() interval_from_bounds(100,10,[2 1]), ...
    @() interval_periodic(100,10,1,0,0,1), ...
    @() interval_between_events(100,10,[2 1]), ...
    @() interval_quantile(100,10,[1 10],2), ...
    @() interval_adaptive(2,10,[1 -1],1), ...
    @() interval_changepoint(2,10,[1 NaN],1), ...
    @() interval_renewal(100,10,[1 0]), ...
    @() interval_stochastic(100,10,2,[3 1],1), ...
    @() interval_poisson(100,10,0,1)};
for j = 1:numel(bad_calls)
    failed = false;
    try
        bad_calls{j}();
    catch
        failed = true;
    end
    assert(failed);
end
disp('interval family regression and invariant checks completed');

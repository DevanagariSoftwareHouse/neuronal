%% b01_bootstrap_firing_rate_area.m

run analysis/a00_startup.m

clc

levels  = 0:15;  % Benchmark before extending to 18
overlap = 0.5;

n_sessions = numel(data);
session_windows = cell(1,n_sessions);

n_workers = 10;

pool = gcp('nocreate');

if ~isempty(pool) && pool.NumWorkers ~= n_workers
    delete(pool);
    pool = [];
end

if isempty(pool)
    pool = parpool('local',n_workers);
end

tic

parfor dd = 1:n_sessions

    % Keep the session data local to this worker
    d = data(dd);

    N  = d.n_lfp_samples;
    Fs = d.srate;

    waveform_id = d.waveform_id(:);

    spike_time = double(d.spike_time.Data.x(:));
    spike_id   = d.spike_cluster.Data.x(:);

    assert(numel(spike_time) == numel(spike_id));

    [mapped, neuron_index] = ismember( ...
        spike_id, waveform_id);

    spike_time   = spike_time(mapped);
    neuron_index = neuron_index(mapped);

    n_neurons = numel(waveform_id);

    n_windows = arrayfun(@(level) ...
        interval_dyadic(N,Fs,level,overlap), levels);

    total_windows = sum(n_windows);

    template = struct( ...
        'nrn_counts', zeros(1,n_neurons), ...
        'duration',   0, ...
        'level',      0, ...
        'window',     0, ...
        'overlap',    overlap ...
    );

    window = repmat(template,total_windows,1);

    w = 0;

    for ll = 1:numel(levels)
    fprintf('Session %d | Level %d | Windows %d\n', ...
            dd, levels(ll), n_windows(ll));
        for ww = 1:n_windows(ll)

            w = w + 1;

            interval = interval_dyadic( ...
                N,Fs,levels(ll),overlap,ww);

            selected = ...
                spike_time >= interval.t0 & ...
                spike_time <  interval.t1;

            counts = accumarray( ...
                neuron_index(selected), ...
                1, ...
                [n_neurons,1], ...
                @sum, ...
                0 ...
            );

            window(w).nrn_counts = counts.';
            %window(w).duration   = interval.duration_s;
            window(w).level      = interval.level;
            window(w).window     = ww;
            %window(w).overlap    = overlap;
            %window(w).t0         = interval.t0;
            %window(w).t1         = interval.t1;

        end
    end

    session_windows{dd} = window;

    fprintf('Session %d finished: %d windows\n', ...
        dd,total_windows);

end

elapsed = toc;

fprintf('Total execution time: %.2f seconds\n',elapsed);

%%

save('session_windows','session_windows','-v7.3')
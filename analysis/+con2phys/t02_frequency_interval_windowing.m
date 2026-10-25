
%% t03_session_window_filter.m

run analysis/a00_startup.m

clearvars -except data
%%
S = load('session_windows.mat', 'session_windows');
session_windows = S.session_windows;
clear S
%% Configuration

cfg = struct();

cfg.sessions  = 1;              % Later: 1:numel(data)
cfg.areas     = {'lfp_1','lfp_2','lfp_3'};
cfg.methods   = {'butterworth'}%, 'cheby1', 'cheby2', ...
                 %'elliptic', 'windowed_fir', 'equiripple_fir'};
cfg.orders    = 4;              % Later: 1:32
cfg.levels    = 0:7;
cfg.overlap   = 0.5;
cfg.use_gpu   = false;

cfg.output_dir = fullfile('data','derived','session_window_filter');

if ~exist(cfg.output_dir, 'dir')
    mkdir(cfg.output_dir);
end

%% Frequency bank

frequency_bands = arrayfun( ...
    @(l) interval_dyadic(250, 1, l, cfg.overlap, 'all'), ...
    cfg.levels, 'UniformOutput', false);

frequency_bands = vertcat(frequency_bands{:});

%% Session loop

n_workers = 3;

pool = gcp('nocreate');

if ~isempty(pool) && pool.NumWorkers ~= n_workers
    delete(pool);
    pool = [];
end

if isempty(pool)
    pool = parpool('local',n_workers);
end

tic
%%

for dd = cfg.sessions

    d = data(dd);

    N  = d.n_lfp_samples;
    Fs = d.srate;

    windows = session_windows{dd};
    
    n_windows = numel(windows);

    % Compute temporal coordinates only once per session.
    geometry = repmat(struct( ...
        'level', 0, ...
        'overlap', 0, ...
        'window', 0, ...
        'first', 0, ...
        'last', 0), n_windows, 1);

    for w = 1:n_windows

        W = windows(w);

        I = interval_dyadic( ...
            N, Fs, W.level, W.overlap, W.window);

        geometry(w).level   = W.level;
        geometry(w).overlap = W.overlap;
        geometry(w).window  = W.window;
        geometry(w).first   = max(1, I.first);
        geometry(w).last    = min(N, I.last);

    end

    %% Area loop

    for la = 1:numel(cfg.areas)

        area_name = cfg.areas{la};

        mmap_lfp = d.(area_name);

        % Assumes samples x channels in the mapped array.
        raw = mmap_lfp.Data.x;
        n_channels = size(raw, 2);

        parfor ch = 1:n_channels

            signal = double(raw(:,ch));
            signal = signal(:);

            if cfg.use_gpu
                signal = gpuArray(signal);
            end

            results = struct([]);
            rr = 0;

            %% Frequency / method / order

            for ff = 1:numel(frequency_bands)

                f = frequency_bands(ff);

                band = [f.t0 f.t1];

                if band(1) < 0 || ...
                   band(2) >= Fs/2 || ...
                   band(2) <= band(1)
                    continue
                end

                for nf = 1:numel(cfg.methods)

                    method = cfg.methods{nf};

                    for oo = 1:numel(cfg.orders)

                        filter_order = cfg.orders(oo);

                        fprintf( ...
                            'Session %s | %s | ch %d | [%g %g] Hz | %s | order %d\n', ...
                            d.id, area_name, ch, ...
                            band(1), band(2), method, filter_order);

                        %% Filter design and execution

                        %fd = filter_design( ...
                        %    method, Fs, band, filter_order);

                        
                        % Esta implementação exige ordens pares para os dois métodos FIR.
                        is_fir = any(strcmp(method, {'windowed_fir','equiripple_fir'}));

                        if is_fir && mod(filter_order, 2) ~= 0
                            continue
                        end

                        if strcmp(method, 'equiripple_fir')

                            % Política inicial: transição de 20% da largura da banda,
                            % limitada para caber estritamente entre DC e Nyquist.
                            margins = [];

                            if band(1) > 0
                                margins(end+1) = band(1);
                            end

                            if band(2) < Fs/2
                                margins(end+1) = Fs/2 - band(2);
                            end

                            transition_hz = 0.20 * diff(band);

                            if ~isempty(margins)
                                transition_hz = min(transition_hz, 0.5 * min(margins));
                            end

                            fd = filter_design(method, Fs, band, filter_order, ...
                                'TransitionHz', transition_hz);

                        else

                            fd = filter_design(method, Fs, band, filter_order);

                        end
                        filtered = filter_do(signal, Fs, fd);

                        %% Analytic signal

                        analytic = hilbert(filtered);

                        amplitude = abs(analytic);
                        phase = angle(analytic);

                        % Derivatives in physical time (seconds).
                        phase_unwrapped = unwrap(phase);

                        angular_speed = ...
                            diff(phase_unwrapped) * Fs;

                        angular_acceleration = ...
                            diff(angular_speed) * Fs;

                        % Move derived features to CPU for statistics.
                        if isa(amplitude, 'gpuArray')
                            amplitude = gather(amplitude);
                            angular_speed = gather(angular_speed);
                            angular_acceleration = ...
                                gather(angular_acceleration);
                        end

                        %% Window statistics

                        mean_amplitude = nan(n_windows, 1);
                        median_amplitude = nan(n_windows, 1);
                        mean_angular_speed = nan(n_windows, 1);
                        median_negative_acceleration = nan(n_windows, 1);
                        n_negative_acceleration = zeros(n_windows, 1);
                        median_positive_acceleration = nan(n_windows, 1);
                        n_positive_acceleration = zeros(n_windows, 1);

                        for w = 1:n_windows

                            i0 = geometry(w).first;
                            i1 = geometry(w).last;

                            if i1 < i0
                                continue
                            end

                            % Amplitude is indexed at sample i.
                            A = amplitude(i0:i1);

                            mean_amplitude(w) = mean(A);
                            median_amplitude(w) = median(A);

                            % diff(phase) belongs to the later sample.
                            if i1 >= max(2,i0)

                                V = angular_speed( ...
                                    max(1,i0-1):i1-1);

                                mean_angular_speed(w) = mean(V);

                            end

                            % diff twice belongs to sample 3 onward.
                            if i1 >= max(3,i0)

                                a0 = max(1,i0-2);
                                a1 = i1-2;

                                acceleration_window = ...
                                    angular_acceleration(a0:a1);

                                negative = acceleration_window( ...
                                    acceleration_window < 0 & ...
                                    isfinite(acceleration_window));

                                n_negative_acceleration(w) = ...
                                    numel(negative);

                                if ~isempty(negative)
                                    median_negative_acceleration(w) = ...
                                        median(negative);
                                end

                                
                                positive = acceleration_window( ...
                                    acceleration_window > 0 & ...
                                    isfinite(acceleration_window));

                                n_positive_acceleration(w) = ...
                                    numel(negative);

                                if ~isempty(positive)
                                    median_positive_acceleration(w) = ...
                                        median(positive);
                                end

                            end

                        end
                        

                        %% Persistent record

                        rr = rr + 1;

                        results(rr).session_id = d.id;
                        results(rr).area = area_name;
                        results(rr).channel = ch;

                        results(rr).band = band;
                        results(rr).method = method;
                        results(rr).order = filter_order;
                        results(rr).fs = Fs;

                        results(rr).design = fd;

                        results(rr).window_id = (1:n_windows)';
                        results(rr).level = [geometry.level]';
                        results(rr).overlap = [geometry.overlap]';
                        results(rr).first = [geometry.first]';
                        results(rr).last = [geometry.last]';

                        results(rr).mean_amplitude = ...
                            mean_amplitude;

                        results(rr).median_amplitude = ...
                            median_amplitude;

                        results(rr).mean_angular_speed = ...
                            mean_angular_speed;

                        results(rr).median_negative_acceleration = ...
                            median_negative_acceleration;

                        results(rr).n_negative_acceleration = ...
                            n_negative_acceleration;
                        
                        results(rr).median_positive_acceleration = ...
                            median_positive_acceleration;

                        results(rr).n_positive_acceleration = ...
                            n_positive_acceleration;

                        return
                    end
                end
            end

            %% Save one file per session / area / channel

            filename = sprintf( ...
                'session_%s_%s_ch%03d.mat', ...
                d.id, area_name, ch);

            output_path = fullfile(cfg.output_dir, filename);

            save(output_path, 'results', 'cfg', '-v7.3');

            fprintf('Saved: %s\n', output_path);

            clear results
        end
    end
end

toc

% NEURONAL MATLAB PATH
% Reusable MATLAB functions for electrophysiology, spike trains, and neural
% population analysis. This directory is the public MATLAB function path.
%
% QUICK START
%   addpath('matlab/path')                 % from the repository root
%   help firing_rate                       % built-in help for one function
%   doc firing_rate                        % MATLAB documentation browser
%   help Contents                          % this function index
%
% Functions accept explicit inputs; they do not load CON2PHYS data implicitly.
% Time is normally seconds, sampling rate is Hz, phase is radians, and samples
% are rows unless a function's help says otherwise. See each function's help
% text for exact input shape, defaults, output order, and assumptions.
%
% EXAMPLE 1 — SPIKE COUNTS AND RATE
%   spikes = [0.10 0.48 0.52 1.25 1.90];  % timestamps in seconds
%   edges = [0 0.5 1.0 1.5 2.0];
%   counts = spike_counts_edges(spikes,edges);  % one count per half-open bin
%   rate = firing_rate(spikes,edges(1),edges(end)); % spikes/s
%
% EXAMPLE 2 — FILTER, SPECTRUM, AND PHASE
%   fs = 500;
%   t = (0:fs*10-1)'/fs;
%   x = sin(2*pi*8*t) + 0.4*sin(2*pi*35*t) + 0.2*randn(size(t));
%   theta = bandpass_lfp(x,fs,[4 12],4);
%   [f,p] = welch_psd(theta,fs,2,0.5);
%   [phase,amplitude] = analytic_phase(theta);
%   plot(f,10*log10(p)); xlabel('Frequency (Hz)'); ylabel('Power (dB)');
%   % Requires Signal Processing Toolbox. Discard filter/Hilbert edge regions
%   % when interpreting phase, and do not treat adjacent samples as replicates.
%
% EXAMPLE 3 — TRIAL-LEVEL BOOTSTRAP
%   rng(7);
%   trial_rate = 8 + 2*randn(30,1);  % independent simulated trials
%   statfun = @(z) mean(z(:,1));
%   [ci,estimate] = bootstrap_ci(trial_rate,statfun,2000,0.95,'percentile',7);
%   % Resample independent trials, not time bins from one continuous recording.
%
% EXAMPLE 4 — PAIRED PHASE CONSISTENCY
%   phase_a = 2*pi*rand(100,1);
%   phase_b = phase_a + 0.25*randn(100,1);
%   value = phase_locking_value(phase_a,phase_b);
%   % This descriptive value does not remove common-reference or stimulus effects.
%
% EXAMPLE 5 — EVENT-ALIGNED SEGMENTS AND TRIGGERED AVERAGE
%   fs = 500;
%   t = (0:fs*4-1)'/fs;
%   lfp = sin(2*pi*8*t) + 0.1*randn(size(t));
%   spike_times = [0.5 1.2 2.1 3.0];  % any event timestamps in seconds
%   [segments,lags_s] = event_aligned_segments(lfp,spike_times,fs,[-0.2 0.3]);
%   [sta,lags_s,n_used] = event_triggered_average(lfp,spike_times,fs,0.2,0.3);
%   plot(lags_s,sta); xlabel('Time from event (s)'); ylabel('Signal');
%   % Edge events are NaN-padded (segments) or skipped (average).
%   % With spikes as events this is the spike-triggered average.
%
% EXAMPLE 6 — SURROGATE TEST OF PAIRING
%   rng(11);
%   x = randn(80,1);
%   y = x + 0.8*randn(80,1);
%   paired_data = [x y];
%   statfun = @(z) corr(z(:,1),z(:,2));
%   shuffle_y = @(z) [z(:,1),z(randperm(size(z,1)),2)];
%   result = surrogate_test(paired_data,statfun,shuffle_y,999,'right');
%   % This tests the chosen pairing null for independent rows; it does not
%   % control temporal dependence if the rows are ordered time samples.
%
% METHOD INDEX
%
% EVENT COUNTS, SPIKE FEATURES, AND SORTING
%   firing_rate                 Mean rate over an exposure interval
%   spike_counts_edges          Counts on explicit half-open bins
%   spike_bin_counts            Equal-width counts on a time interval
%   spike_bins                  Counts for multiple units
%   interspike_intervals        Successive spike-time differences
%   trial_features              Trial-by-unit rates in specified windows
%   spike_count_fano            Fano factor across trials
%   noise_correlation           Condition-residual correlation
%   condition_marginalization   Condition means and residuals
%   autocorrelogram             Binned autocorrelation
%   crosscorrelogram            Binned cross-correlation
%   spike_threshold_detection   Negative-threshold spike candidates
%   spike_waveform_extraction   Waveform snippets at event indices
%   spike_waveform_average      Mean waveform and standard error
%   spike_waveform_pca          SVD features for waveforms
%   spike_waveform_snr          Robust waveform-to-noise ratio
%   waveform_trough_to_peak     Waveform trough-to-peak duration
%   template_match_waveforms   Cosine similarity to templates
%   spike_refractory_violations Fraction of short inter-spike intervals
%   spike_presence_ratio        Fraction of occupied time bins
%   spike_sorting_agreement     Tolerance-matched sorting agreement
%   victor_purpura_distance     Edit distance between spike trains
%
% EVENT ALIGNMENT
%   sparse_count_matrix        Sparse label-by-sample counts of timestamps
%   amplitude_threshold_events Threshold-defined event candidates
%   phase_crossing_events      Interpolated phase crossings
%   event_aligned_segments     Event x lag segments of any sampled signal
%   event_triggered_average    Signal average around event times (STA)
%   peri_event_histogram       Trial-by-bin event counts and rates
%   plot_event_aligned         Display an event x lag matrix
%
% SPECTRA, FILTERS, OSCILLATIONS, AND LFP
%   welch_psd                  One-sided Welch power spectral density
%   multitaper_psd             DPSS multitaper power spectrum
%   aperiodic_slope            Log-log aperiodic spectral slope
%   irasa_decomposition        IRASA-style fractal/oscillatory split
%   spectral_peak_candidates   Heuristic spectral peak candidates
%   spectral_entropy           Normalised spectral entropy
%   permutation_entropy        Ordinal-pattern entropy
%   bandpass_lfp               Forward-backward Butterworth filter
%   analytic_phase             Hilbert analytic phase and amplitude
%   morlet_wavelet             Unit-energy Morlet convolution
%   empirical_mode_decomposition EMD modes and residual
%   ensemble_empirical_mode_decomposition EEMD modes and residual
%   cycle_by_cycle             Cycle features from zero crossings
%   bosc_detect                BOSC-style oscillation episode detection
%   oscillation_episode        Episodes from a threshold mask
%   ripple_candidate_events    Robust-envelope ripple candidates
%   lfp_envelope_moments       Moments of theta/beta/gamma envelopes
%   bipolar_reference_lfp      Adjacent-channel differences
%   common_median_reference    Common-median referencing
%   current_source_density     One-dimensional second difference
%   field_potential_forward    Apply a supplied lead field
%   field_potential_inverse_tikhonov Regularised inverse estimate
%
% COUPLING, PHASE, AND INFORMATION
%   coherence_spectrum         Welch magnitude-squared coherence
%   multitaper_coherence       Multitaper coherence
%   wavelet_coherence          Time-frequency wavelet coherence
%   phase_slope_index          Frequency-domain phase-slope index
%   phase_locking_value        Phase-difference resultant magnitude
%   phase_lag_index            Sign consistency of phase lags
%   weighted_phase_lag_index   Imaginary coherency weighting
%   circular_mean              Weighted circular mean and resultant length
%   rayleigh_test              Rayleigh test for circular uniformity
%   pairwise_phase_consistency Pairwise phase consistency
%   modulation_index           Phase-binned amplitude modulation index
%   pac_mean_vector_length     Phase-amplitude mean-vector length
%   second_order_modulation    Slow-phase dependence of PAC depth and PM index
%   simulate_lfp_modulation    Synthetic LFP with 1st/2nd-order AM and PM, ground truth
%   mutual_information         Plug-in mutual information
%   transfer_entropy           First-order plug-in transfer entropy
%   granger_causality          Conditional linear VAR Granger causality
%   spike_field_coherence      Spike-count/LFP coherence
%   spike_field_ppc            Spike-phase pairwise consistency
%
% SURROGATES, RESAMPLING, AND INFERENCE
%   circular_shift_surrogate   Circular shift surrogate
%   phase_randomized_surrogate Fourier phase-randomised surrogate
%   aaft_surrogate             Amplitude-adjusted Fourier surrogate
%   iaaft_surrogate            Iterative amplitude-adjusted Fourier surrogate
%   multivariate_phase_surrogate Shared-phase multichannel surrogate
%   block_shuffle_surrogate    Permuted contiguous blocks
%   interval_jitter_surrogate  Spike relocation within fixed intervals
%   jitter_spike_surrogate     Window-jitter spike surrogate
%   spike_dither_surrogate     Independent spike-time dithering
%   local_permutation_surrogate Neighbour-based conditional surrogate
%   trial_shuffle_surrogate    Trial-label shuffle surrogate
%   surrogate_test             Monte Carlo surrogate test
%   surrogate_maxstat_test     Familywise maximum-statistic surrogate test
%   permutation_test           Two-sample label-permutation test
%   paired_permutation_test    Paired sign-flip permutation test
%   paired_difference_ci      Bootstrap interval for matched differences
%   paired_signflip_test       Paired sign-flip randomisation test
%   maxstat_permutation_test   Maximum-statistic permutation test
%   cluster_permutation_test   Cluster-mass permutation test
%   monte_carlo_null_test      Monte Carlo test from a null generator
%   bootstrap_percentile       Percentile bootstrap interval for means
%   bootstrap_ci               IID percentile/basic/BCa bootstrap interval
%   bootstrap_t_ci             Studentised IID bootstrap interval
%   block_bootstrap_ci         Moving-block or stationary-bootstrap interval
%   jackknife_estimate         Delete-one-row jackknife estimates
%   jackknife_ci               Normal-approximation jackknife interval
%   delete_group_jackknife     Leave-one-group-out jackknife
%   hierarchical_bootstrap_ci  Nested animal/trial bootstrap interval
%   parametric_bootstrap_ci    Model-based parametric bootstrap interval
%   subsampling_ci             Subsampling confidence interval
%   simultaneous_confidence_band Max-t simultaneous bootstrap band
%   posterior_predictive_check Posterior-predictive diagnostic
%   sensitivity_analysis       Evaluate caller-specified configurations
%   stability_selection        Feature selection frequency by subsampling
%
% VALIDATION, DECODING, AND POPULATION METHODS
%   blocked_cross_validation   Contiguous folds with an exclusion gap
%   group_cross_validation     Group-disjoint cross-validation folds
%   crossvalidated_ridge_decoder Fold-wise ridge decoding
%   decode_trials              Contiguous-fold multiclass decoder
%   decoded_mi                 Mutual information of labels and predictions
%   linear_discriminability    Pooled-covariance linear d-prime squared
%   population_pca             PCA of centred population activity
%   participation_ratio        Participation ratio of singular values
%   population_dimension_scaling Participation ratio vs. population size
%   eigenspectrum_powerlaw     Power-law fit to covariance eigenvalues
%   assembly_pca               PCA-based assembly templates
%   assembly_expression        Off-diagonal assembly expression
%   targeted_dimensionality_reduction Targeted two-condition basis
%   reduced_rank_regression    Reduced-rank ridge regression
%   communication_subspace_projection Projection into source axes
%   jpca_dynamics              Skew-symmetric population dynamics fit
%   tensor_cp_als              Ridge CP-ALS tensor factorisation
%   gaussian_process_smoothing Kernel-ridge Gaussian-process smoother
%   greedy_modularity          Greedy weighted modularity merging
%   poisson_spike_glm          Ridge Poisson GLM for spike counts
%   spike_history_design       Lagged spike-history design matrix
%   coupling_filters           Per-target Poisson coupling filters
%
% DATA CATALOG AND BINARY STORAGE
%   neuronal_catalog           Load dataset metadata only
%   neuronal_file_path         Resolve a data descriptor path
%   neuronal_memmap            Read-only memory-map for binary recordings
%   neuronal_read              Read selected samples/channels from a map
%   neuronal_validate_file     Validate a binary recording descriptor
%   neuronal_register          Validate and register a dataset
%   neuronal_write_binary      Write chunked little-endian binary data
%
% SCIENTIFIC USE
%   These functions are exploratory analysis primitives. Review the individual
%   function help before use: most statistical procedures rely on assumptions
%   about independent units, exchangeability, stationarity, or model fit.
%   Bootstrap and surrogate results are only as defensible as the resampling
%   unit and null generator. Connectivity metrics do not establish causation.
%
% See also firing_rate, spike_counts_edges, welch_psd, bandpass_lfp,
% analytic_phase, bootstrap_ci, phase_locking_value, event_aligned_segments.

% Compatibility names (prefer the generic event API in new code)
%   spike_raster_sparse - Compatibility wrapper; see sparse_count_matrix.
%   event_aligned_raster - Compatibility wrapper; see event_aligned_segments.
%   plot_event_raster - Compatibility wrapper; see plot_event_aligned.
%   spike_triggered_average - Compatibility wrapper; see event_triggered_average.

% INTERVAL GENERATORS (see ../INTERVALS.md)
%   interval_adaptive - Partition samples by accumulated nonnegative mass.
%   interval_at - Lazily calculate a multiscale overlapping session interval.
%   interval_behavioral - Generate intervals from paired behavioral or trial boundaries.
%   interval_between_events - Generate gaps between consecutive ordered events.
%   interval_changepoint - Partition by greedy binary segmentation of changes in mean.
%   interval_dyadic - Lazily generate a dyadic interval with explicit overlap.
%   interval_event - Generate windows around event times.
%   interval_from_bounds - Convert K-by-2 time bounds in seconds to sampled interval records.
%   interval_geometric - Lazily generate contiguous geometrically growing intervals.
%   interval_madic - Lazily generate an m-adic interval, optionally overlapping.
%   interval_periodic - Lazily generate a positive run of a periodic square wave.
%   interval_poisson - Generate exponential renewal intervals for a homogeneous Poisson model.
%   interval_quantile - Partition time at empirical timestamp quantiles.
%   interval_renewal - Generate renewal intervals from supplied positive waiting times.
%   interval_sliding - Lazily generate the Kth complete sliding window.
%   interval_stochastic - Draw complete random windows with reproducible local RNG state.
%   interval_threshold - Generate contiguous runs strictly above a scalar threshold.
%   interval_uniform - Lazily select an equal-duration partition.
%   interval_wavelet - Generate the affine support interval of a wavelet atom.

% LAYERED FILTER FAMILY (see matlab/FILTERS.md)
%   filter_analytic                 - Hilbert analytic signal of already filtered real voltage.
%   filter_butterworth              - Design butterworth coefficients for a frequency interval.
%   filter_causal                   - Apply design to a chunk and return exact continuation states.
%   filter_chebyshev1               - Design cheby1 coefficients for a frequency interval.
%   filter_chebyshev2               - Design cheby2 coefficients for a frequency interval.
%   filter_csd                      - One-dimensional finite-difference current-source density.
%   filter_cwt                      - Analytic CWT for one channel using the Wavelet Toolbox backend.
%   filter_design                   - Design a classical pass filter independently of application.
%   filter_despike                  - Interpolate explicitly marked spike neighborhoods.
%   filter_dyadic                   - Lazy dyadic frequency bank with interval_* conventions.
%   filter_elliptic                 - Design elliptic coefficients for a frequency interval.
%   filter_emd                      - Empirical mode decomposition using MATLAB EMD.
%   filter_equiripple_fir           - Design equiripple_fir coefficients for a frequency interval.
%   filter_forward_backward         - Offline zero-phase filtering of a complete record.
%   filter_joint_decorrelation      - Whiten reference covariance and diagonalize target.
%   filter_line_regression          - Remove fitted sinusoids at specified line frequencies.
%   filter_logarithmic              - Lazy constant-ratio bands between FMIN and Nyquist.
%   filter_modwpt                   - Full-rate terminal wavelet packet coefficients for one channel.
%   filter_modwpt_details           - Reconstructed terminal packet contributions.
%   filter_multitaper               - Thomson windowed PSD, in signal-units squared per Hz.
%   filter_open                     - Validate and memory-map a FILTER_WRITE artifact, read-only.
%   filter_overlap                  - Lazy sliding frequency intervals of explicit width in Hz.
%   filter_pad                      - Explicit sample padding with indices to crop the result.
%   filter_phase                    - Wrapped phase in radians of explicit analytic coefficients.
%   filter_power                    - Squared magnitude of explicit real or complex coefficients.
%   filter_read                     - Read selected array indices from a persistent filter artifact.
%   filter_rereference              - Common mean/median or explicit bipolar channel pairs.
%   filter_robust_detrend           - Polynomial trend fitted by Huber IRLS per channel.
%   filter_spectrum_interpolation   - Replace contaminated FFT magnitudes.
%   filter_ssd                      - Spatial-spectral decomposition with explicit target/noise designs.
%   filter_state                    - Construct zero continuation states for a design and channels.
%   filter_stft                     - Complex short-time Fourier coefficients, not filtered voltage.
%   filter_uniform                  - Count or retrieve full-width frequency intervals over Nyquist.
%   filter_vmd                      - Variational mode decomposition using MATLAB VMD.
%   filter_windowed_fir             - Design windowed_fir coefficients for a frequency interval.
%   filter_wpt                      - Decimated terminal wavelet packet coefficients in frequency order.
%   filter_write                    - Persist an immutable typed array as binary plus manifest.
%   filter_zapline                  - Adapter to the original NoiseTools NT_ZAPLINE implementation.

% RESOURCE AND STORAGE ESTIMATION (see RESOURCE_README.md)
%   estimate_resource             - Generic or function-specific CPU/GPU working-memory estimate.
%   storage_estimate              - Estimated RAM and disk for dense storage_read/storage_write.
%   resource_snapshot             - Snapshot RAM, CPU load, disk capacity and optional GPU VRAM.
%   resource_storage              - Inspect available filesystem space and Linux I/O pressure.
%   resource_admit                - Advisory admission accounting for in-flight reservations.
%   resource_batch_size           - Maximum admissible identical-task concurrency.
%   resource_wait                 - Timeout-bounded cooperative resource polling.
%   resource_gpu_sync             - Synchronize work submitted to the selected GPU.
%   resource_estimate             - Legacy alias for estimate_resource(N,...).
%   resource_estimate_function    - Compatibility function-specific estimator dispatcher.

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
% METHOD INDEX
%
% EVENT COUNTS, SPIKE FEATURES, AND SORTING
%   firing_rate                 Mean rate over an exposure interval
%   spike_counts_edges          Counts on explicit half-open bins
%   spike_bin_counts            Equal-width counts on a time interval
%   spike_bins                  Counts for multiple units
%   interspike_intervals        Successive spike-time differences
%   peri_event_histogram        Trial-by-bin event counts and rates
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
%   spike_raster_sparse         Sparse cluster-by-time count matrix
%
% EVENT ALIGNMENT AND SPIKE-TRAIN METHODS
%   amplitude_threshold_events Threshold-defined event candidates
%   phase_crossing_events      Interpolated phase crossings
%   event_aligned_raster       Event-aligned count matrix
%   plot_event_raster          Display event-aligned counts
%   spike_triggered_average    Signal average around spike times
%   victor_purpura_distance   Edit distance between spike trains
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
% analytic_phase, bootstrap_ci, phase_locking_value, spike_triggered_average.

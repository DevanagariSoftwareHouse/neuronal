# Coupling, phase statistics and information (MATLAB)

[Índice](README.md) · [Anterior](06_EVENT_ALIGNMENT.md) · [Próximo](08_POPULATION.md)

The primitives in `path/` separate **spectral coupling between two
signals**, **phase-based synchrony**, **circular statistics**,
**spike-field relations**, **cross-frequency coupling**, and **information
and predictive dependence**. All of them are descriptive or
assumption-laden statistics: a nonzero value does not establish an
interaction, and none removes volume conduction, common reference, shared
stimulus drive or rate differences by itself. Pair every estimate with a
null from [10_SURROGATES.md](10_SURROGATES.md) and an inference unit from
[11_INFERENCE.md](11_INFERENCE.md).

Two finite vectors of equal length sampled at `srate` from time zero are
the default input; phases are radians.

## 1. Spectral coherence

```matlab
[f, C] = coherence_spectrum(lfp_a, lfp_b, fs, 4);
[fm, Cm] = multitaper_coherence(lfp_a, lfp_b, fs, 4, 3);    % NW = 3, K = 5
fw = 4:2:40;
[Cw, fw, t_s] = wavelet_coherence(lfp_a, lfp_b, fs, fw, 6, .5);
[psi, fpsi, coherency] = phase_slope_index(lfp_a, lfp_b, fs, [6 10], 4);
```

`coherence_spectrum` is Welch magnitude-squared coherence (`mscohere`,
periodic Hann, 50% overlap, at least two windows); it is bounded in `[0,1]`
and biased upward when few segments are averaged. `multitaper_coherence`
averages DPSS cross- and auto-spectra over 50%-overlapping demeaned
segments, without jackknife or trial statistics. `wavelet_coherence`
smooths Morlet cross- and auto-spectra in time only (`smoothing_seconds`,
default 0.5) and sets the wavelet support at each edge to `NaN`; inputs are
capped at 5e6 frequency x time values and there is no cross-scale
smoothing. `phase_slope_index` sums the imaginary part of adjacent-bin
coherency products over at least three contiguous bins of the band; it is
unnormalised, and its sign follows the `cpsd` convention, to be fixed with a
known-delay test ([12_REVIEW.md](12_REVIEW.md)). Coherence is undirected.

## 2. Phase synchrony

```matlab
[pa, ~] = analytic_phase(bandpass_lfp(lfp_a, fs, [6 10]));
[pb, ~] = analytic_phase(bandpass_lfp(lfp_b, fs, [6 10]));
plv = phase_locking_value(pa(valid), pb(valid));
pli = phase_lag_index(pa(valid) - pb(valid));
wpli = weighted_phase_lag_index(cross_spectra_per_trial);    % complex
```

`phase_locking_value` is `|mean(exp(i*(a-b)))|` over matched finite samples;
it does not remove common-reference or stimulus effects. `phase_lag_index`
is `|mean(sign(sin(dphi)))|`: zero- and antiphase terms count as zero but
stay in the denominator, and sines within `10*eps` of zero are rounded to
zero. `weighted_phase_lag_index` weights the sign by `|imag|` over complex
cross-spectrum estimates, one per segment or trial (not the debiased wPLI).
Adjacent samples of one recording are not independent observations.

## 3. Circular summaries

```matlab
[mu, r] = circular_mean(spike_phase);             % optional nonnegative weights
test = rayleigh_test(spike_phase);                % p_value, z, resultant_length
ppc = pairwise_phase_consistency(spike_phase);
```

`circular_mean` returns the (weighted) mean direction and resultant length;
the direction is `NaN` when the resultant is numerically zero.
`rayleigh_test` needs at least five angles and returns `p_value`, `z`,
`resultant_length`, `n`, `mean_direction` and a `note`; it assumes
independent samples and a unimodal alternative. `pairwise_phase_consistency`
is `(|sum z|^2 - n)/(n(n-1))`, unbiased with respect to the number of
events under independence; it can be negative.

## 4. Spike-field relations

```matlab
theta = bandpass_lfp(lfp, fs, [6 10]);
[ppc, spike_phase] = spike_field_ppc(theta, unit_s, fs, 2);
[f, sfc] = spike_field_coherence(lfp, unit_s, fs, 4);
```

`spike_field_ppc` interpolates the analytic signal of a **prefiltered**
narrow-band LFP at each spike time, after discarding spikes within
`edge_seconds` (default 2) of either end, and returns the PPC and the spike
phases. `spike_field_coherence` bins spikes at the LFP rate (containing
sample) and computes Welch coherence with the LFP; it **rejects** spikes
outside the recording instead of discarding them, and the value depends on
firing rate, so comparisons across units or conditions are confounded. For
event-locked waveforms use `event_triggered_average`
([06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md)).

## 5. Phase-amplitude coupling

```matlab
[ph, ~] = analytic_phase(bandpass_lfp(lfp, fs, [6 10]));
[~, ga] = analytic_phase(bandpass_lfp(lfp, fs, [30 80]));
[mi, amp_by_phase, edges] = modulation_index(ph(valid), ga(valid), 18);
mvl = pac_mean_vector_length(ph(valid), ga(valid));
```

`modulation_index` is the Tort et al. normalised KL divergence of the
phase-binned mean amplitude from uniform (default 18 bins, at least two
observations per bin); empty bins give `NaN`. `pac_mean_vector_length`
returns `raw_mvl` (in amplitude units), `normalized_mvl` (divided by mean
amplitude, in `[0,1]`), `preferred_phase_rad` and the number of
observations. Both are descriptive: non-sinusoidal waveforms and harmonics
create spurious coupling, and the high band must be wide enough to carry
the low-frequency sidebands.

## 6. Information and predictive dependence

```matlab
bits = mutual_information(stimulus_label, count_label);   % discrete labels
te = transfer_entropy(source_states, target_states);       % first order
g = granger_causality(binned_activity, 1, 2, 5);           % source, target, lags
```

`mutual_information` is the plug-in estimate in bits for finite numerical
labels; continuous values must be discretised first, and the finite-sample
bias is not corrected. `transfer_entropy` is
`I(target[t]; source[t-1] | target[t-1])` on discrete states, clipped at
zero, without bias correction. `granger_causality` compares full and reduced
least-squares VAR(`lags`) models for one target over all columns of a time
x variables matrix and returns `log_variance_ratio`, both residual
variances, the sample count and the indices. These quantify **predictive**
dependence under model assumptions, not physical causality; check residuals
and stationarity, and calibrate with conditional surrogates.

## Tests

From the repository root:

```matlab
run('matlab/tests/smoke_arsenal.m')            % coherence, PLV/PLI/wPLI, PPC, MI, PAC, TE, Granger
run('matlab/tests/smoke_ephys_methods.m')      % multitaper, wavelet and spike-field coherence
run('matlab/tests/smoke_bosc_circ_glm.m')      % circular mean, Rayleigh
run('matlab/tests/smoke_consensus_methods.m')  % mean vector length
run('matlab/tests/check_arsenal_identities.m') % PPC, PLI, wPLI, MI, TE, Granger identities
```

No script calls `phase_slope_index` yet. Synthetic tests cover bounds and
known couplings; they do not establish calibrated null distributions.

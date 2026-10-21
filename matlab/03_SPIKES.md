# Spike detection, waveforms and unit quality (MATLAB)

[Índice](README.md) · [Anterior](02_PREPROCESSING.md) · [Próximo](04_SPIKE_TRAINS.md)

The primitives in `path/` separate **candidate detection**, **waveform
extraction**, **waveform description**, and **unit quality metrics**.
Together they are the elements of a sorting pipeline, not a sorter: there is
no clustering, drift correction, multi-unit matching or curation here.
Everything in this chapter needs **broadband action-potential data** at the
real acquisition rate (for example 30 kHz). The CON²PHYS LFP at 500 Hz has
a 250 Hz Nyquist and cannot resolve spike waveforms.

## Primer: from voltage excursions to labelled events

“When did a detectable extracellular event occur?” and “Which source
generated it?” are different questions. Detection finds candidates in a
voltage trace. Sorting assigns labels using waveform and other structure.
Quality assessment asks whether a labelled cluster is stable and adequately
isolated. A cluster ID is an identifier, not proof of a single neuron.

A simplified recording model is

$$
x_c[n]=\sum_u\sum_i a_{ui}w_{cu}[n-n_{ui}]+\epsilon_c[n],
$$

where $c$ indexes channels, $u$ putative sources, $n_{ui}$ event samples,
$w_{cu}$ templates, $a_{ui}$ amplitude changes, and $\epsilon_c$ background.
Overlapping templates and changing amplitudes explain why thresholding
alone cannot recover all source identities.

### Toy experiment: recover known event times

```matlab
run('matlab/neuronal_startup.m')
rng(21)
fs_ap = 30000;
t = (0:2*fs_ap-1)'/fs_ap;
truth_s = (.2:.2:1.8)';
ap = .15*randn(size(t));
for k = 1:numel(truth_s)
    ap = ap - 3*exp(-.5*((t-truth_s(k))/.00015).^2);
end
[detected_s, detected_idx, threshold] = ...
    spike_threshold_detection(ap, fs_ap, 4, .001);
agreement = spike_sorting_agreement(truth_s, detected_s, .0005);
disp(agreement)
plot(t, ap); hold on
plot(detected_s, ap(detected_idx), 'ro'); hold off
xlim([.19 .21]); xlabel('Time (s)'); ylabel('Voltage (arbitrary units)');
```

This deliberately simple negative-pulse model is a detection exercise,
not a physiological waveform simulation. Increasing the threshold tends
to trade false detections for missed events. Increasing noise or adding
overlapping pulses tests different failure mechanisms. Report both
precision and recall: either alone hides part of the trade-off.

### Quality criteria must match the downstream question

Refractory violations can reveal duplicates or merged sources, but low
violation counts do not establish purity. A high presence ratio can reflect
a high rate; a low ratio can reflect genuine sparse activity. Template
similarity can reflect duplicate clusters. Examine several diagnostics
jointly and state inclusion rules before comparing brain areas.

For CON²PHYS analyses based on supplied clusters, preserve the mapping
between spike labels, waveform labels and brain areas. Use the supplied
spike timestamps directly; the 500 Hz LFP cannot be used to reconstruct
the broadband events in this example. If a question is about clusters,
report cluster-level results and the inclusion criteria explicitly.

**Exercise.** Add a second event 0.5 ms after each known event. How does the
detector's minimum separation change the apparent event count? Distinguish
this algorithmic exclusion from a biological refractory period.

## 1. Threshold candidates

```matlab
fs_ap = 30000;
[spike_s, spike_idx, thr] = spike_threshold_detection(ap, fs_ap, 4, .001);
```

The noise scale is the robust `median(|x - median(x)|)/0.6745`; candidates
are negative peaks of `-x` above `threshold_sigma` (default 4) times that
scale, at least `refractory_s` apart (default 1 ms). `spike_idx` are MATLAB
1-based sample indices and `spike_s = (spike_idx-1)/fs`, so sample 1 is time
zero, the same origin used everywhere in this path. Requires `findpeaks`.
Detection is **not** sorting and does not reject artifacts.

## 2. Waveform snippets and templates

```matlab
% recording: channels x samples, broadband, same rate as spike_idx.
[waves, kept] = spike_waveform_extraction(recording, spike_idx, 30, 60);
[template, sem] = spike_waveform_average(waves(1:min(end,500),:,:));
noise = recording(:, 1:fs_ap);              % a spike-free stretch if known
quality = spike_waveform_snr(template, noise);
width_ms = waveform_trough_to_peak(template(quality.channel,:), fs_ap);
```

`spike_waveform_extraction` returns **spikes x channels x samples** in
`single`, `before + after + 1` samples per snippet, keeping only indices
with a complete window; `kept` points into the input index vector. Batches
are capped at 2e7 values. `spike_waveform_average` returns the mean and SEM
as **channels x samples**, also for one channel (no `squeeze`).
`spike_waveform_snr` divides each channel's peak absolute template value by
that channel's robust noise (at least 10 noise samples) and reports the
best channel in `snr`/`channel` and all values in `by_channel`.
`waveform_trough_to_peak` measures the time from the global minimum to the
following maximum, in ms (`NaN` when the trough is the last sample). Width
classes are a heuristic, **not** a cell-type identification.

## 3. Waveform features and template similarity

```matlab
flat = reshape(waves(:,quality.channel,:), size(waves,1), []);
features = spike_waveform_pca(double(flat), 3);
[template_id, cosine] = template_match_waveforms(double(flat), templates);
```

`spike_waveform_pca` centres rows (waveforms) and returns `scores`,
`loadings` and `mean` from an economy SVD. `template_match_waveforms`
assigns each waveform to the template with the highest cosine similarity;
waveforms and templates are rows of equal length and nonzero norm. PCA
alone is not sorting, and the template matcher is **not** Kilosort4.

## 4. Unit quality metrics

```matlab
rv = spike_refractory_violations(unit_s, .002);
pr = spike_presence_ratio(unit_s, 0, duration_s, 60);
agreement = spike_sorting_agreement(truth_s, unit_s, .0005);
```

`spike_refractory_violations` counts adjacent inter-spike intervals shorter
than the threshold (default 2 ms); `fraction` is a violation proportion,
**not** a calibrated contamination estimate. `spike_presence_ratio` is the
fraction of complete bins containing at least one spike; the incomplete tail
is reported in `unused_tail_seconds`, and empty bins can simply reflect a
low rate. `spike_sorting_agreement` greedily matches sorted times one-to-one
within the tolerance (default 0.5 ms) and returns true/false positives,
false negatives, precision, recall and F1. It assumes one reference unit is
already paired with one estimated unit; it does **not** solve multi-unit
assignment.

## Tests

From the repository root:

```matlab
run('matlab/tests/smoke_arsenal.m')            % detection, PCA, templates, width
run('matlab/tests/smoke_ephys_methods.m')      % extraction, average, SNR, QC
run('matlab/tests/check_arsenal_identities.m') % sorting agreement identities
```

Synthetic tests cover shapes, single-channel layouts and exact matches.
They do not replace ground-truth recordings, duplicate-unit tests, drift or
comparison against SpikeInterface and Kilosort4.

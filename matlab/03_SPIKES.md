# Spike detection, waveforms and unit quality (MATLAB)

[Índice](README.md) · [Anterior](02_PREPROCESSING.md) · [Próximo](04_SPIKE_TRAINS.md)

The primitives in `path/` separate **candidate detection**, **waveform
extraction**, **waveform description**, and **unit quality metrics**.
Together they are the elements of a sorting pipeline, not a sorter: there is
no clustering, drift correction, multi-unit matching or curation here.
Everything in this chapter needs **broadband action-potential data** at the
real acquisition rate (for example 30 kHz). The CON²PHYS LFP at 500 Hz has
a 250 Hz Nyquist and cannot resolve spike waveforms.

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

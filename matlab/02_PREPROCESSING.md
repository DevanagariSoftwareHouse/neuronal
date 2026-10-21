# Referencing, filtering and field geometry (MATLAB)

[Índice](README.md) · [Anterior](01_STORAGE.md) · [Próximo](03_SPIKES.md)

Six primitives in `path/` act on sampled voltages **before** any spectral,
event or coupling analysis: re-referencing, zero-phase band limitation,
laminar second differences, and a supplied linear lead field in both
directions. None of them removes artifacts or validates a recording; each
one changes what a later estimator measures.

| Function | Input layout | Output |
| --- | --- | --- |
| `common_median_reference` | channels x samples | referenced signal, common median |
| `bipolar_reference_lfp` | depth-ordered channels x samples, depths | adjacent differences, midpoint depths |
| `bandpass_lfp` | one vector | zero-phase bandpassed vector, same orientation |
| `current_source_density` | depth-ordered channels x samples | CSD, NaN on the outer contacts |
| `field_potential_forward` | electrodes x sources, sources x samples | electrodes x samples |
| `field_potential_inverse_tikhonov` | electrodes x sources, electrodes x samples | struct with sources, prediction, residual |

Note the layout: these functions take **channels x samples**, whereas
`neuronal_read` returns samples x channels ([01_STORAGE.md](01_STORAGE.md)).
Transpose a bounded block, never the whole recording.

## Primer: every transformation changes the measurement

Start with “Which unwanted contribution am I trying to suppress, and which
biological contribution might be suppressed with it?” Referencing operates
across space; temporal filtering operates across time. Neither operation
can identify an artifact from its name alone.

For a linear time-invariant filter, the output is a weighted sum of input
samples:

$$
y[n]=\sum_k h[k]x[n-k],
$$

where $h[k]$ is the impulse response and $n$ is the sample index. A localized
input can therefore affect many output samples. Forward-backward filtering
has zero phase in its ideal interior response, but uses future samples:
it can spread a post-event transient into pre-event time. Zero phase does
not mean unchanged waveform or valid online prediction.

### Toy experiment: an impulse becomes an oscillatory waveform

```matlab
run('matlab/neuronal_startup.m')
fs = 500;
t = (0:10*fs-1)'/fs;
impulse = zeros(size(t));
impulse(round(5*fs)+1) = 1;
filtered = bandpass_lfp(impulse, fs, [6 10], 4);
plot(t, impulse, 'k', t, filtered, 'b');
xlim([4 6]); xlabel('Time (s)'); ylabel('Amplitude (input units)');
legend('Input impulse', 'Bandpassed output'); grid on
```

The input contains one transient, yet the bandpassed trace has alternating
lobes. This is a demonstration of the filter, not evidence for an ongoing
8 Hz neural generator. Compare the impulse response for `[4 12]` and
`[7 9]` Hz; narrower frequency selection generally spreads activity over
more time. Inspect the actual response rather than treating the two-second
edge margin used elsewhere as a universal guarantee.

### Spatial transformations answer different questions

For electrode voltage $v_c(t)$, common-median reference forms
$v_c(t)-\operatorname{median}_j v_j(t)$. A component identical across all
channels vanishes, whether it came from interference or a shared neural
source. Bipolar differences emphasize spatial changes. CSD takes a second
spatial difference under a physical geometry and conductivity model.
Comparing these representations is a sensitivity analysis, not a vote
between interchangeable estimates.

For CON²PHYS, inspect raw channels and artifacts first, choose a reference
with anatomical justification, filter padded blocks, and retain only the
interior interval for downstream analysis. Keep masks for excluded samples;
joining disconnected valid intervals creates artificial temporal neighbours.
In predictive analyses, preprocessing must also respect the train/test
boundary and the information available at prediction time.

**Exercise.** Add an identical sine wave to every channel, then apply common
median reference. Which scientific questions become impossible after that
shared component is removed?

**Reading.** de Cheveigné & Nelken (2019), *Filters: When, Why, and How (Not)
to Use Them*, [doi:10.1016/j.neuron.2019.02.039](https://doi.org/10.1016/j.neuron.2019.02.039),
develops the impulse-response interpretation and the reporting implications.

## 1. Common-mode and bipolar references

```matlab
% Ten seconds of every channel at 500 Hz, transposed to channels x samples.
block = double(neuronal_read(m, 1:5000)).';
[cmr, common] = common_median_reference(block);

depth_m = (0:size(block,1)-1)' * 20e-6;   % ONLY if the order is validated
[bip, mid_depth_m] = bipolar_reference_lfp(block, depth_m);
```

`common_median_reference` subtracts the median across channels at every
sample (at least two channels, all finite). It suppresses common-mode noise
**and** any neural signal genuinely shared by all contacts.
`bipolar_reference_lfp` returns `diff(x,1,1)`: row `k` is channel `k+1`
minus channel `k`, located at the midpoint depth. Depths must be strictly
increasing; the nominal 20 um pitch is not a validated coordinate. A bipolar
derivation is a first spatial difference, **not** a CSD estimate. Compare
reference schemes before interpreting phase or coherence.

## 2. Zero-phase band limitation

```matlab
fs = 500;
theta = bandpass_lfp(x, fs, [6 10]);        % order 4 by default
gamma = bandpass_lfp(x, fs, [30 80], 4);
valid = (1:numel(x))' > 2*fs & (1:numel(x))' <= numel(x) - 2*fs;
```

A Butterworth design in second-order sections is applied forward and
backward with `filtfilt`, so the effective magnitude response is squared
and the phase is zero. The band must lie strictly inside `(0, Nyquist)` and
the input must be a finite vector longer than `max(30, 6*order)` samples;
a row input returns a row. Edge transients are **not** removed: discard a
margin (above, two seconds) before using phase or envelope. Filtering is
not artifact removal, and a narrow band imposes oscillatory structure on
broadband noise.

## 3. Laminar current source density

```matlab
spacing_m = 20e-6;   % equal, validated contact spacing
sigma = 0.3;         % S/m, homogeneous conductivity assumption
csd = current_source_density(lfp_by_depth, spacing_m, sigma);
```

The estimate is the negative second spatial difference
`-sigma*(x(k+1)-2x(k)+x(k-1))/h^2`, defined on interior contacts only;
the first and last rows are `NaN`. It assumes a one-dimensional laminar
geometry, equal spacing and homogeneous conductivity (default 1, i.e.
unscaled). It is **not** iCSD and does not correct for finite source
extent or missing boundary contacts.

## 4. Supplied lead field: forward and regularised inverse

```matlab
% G: electrodes x source locations, from an external physical model.
v = field_potential_forward(G, sources);            % electrodes x samples
fit = field_potential_inverse_tikhonov(G, v, 1e-3);
plot(fit.residual(1,:));
```

`field_potential_forward` is the matrix product `G*s`; no lead field is
constructed or inferred. `field_potential_inverse_tikhonov` returns
`sources = (G'G + lambda I) \ G'y` with `prediction`, `residual`,
`lambda` and a `note`. The inverse is ill-posed: the ridge solution is
**one** regularised estimate, never a unique physiological source, and
the primal form is costly when sources far outnumber electrodes (see
[12_REVIEW.md](12_REVIEW.md)). Excitation/inhibition or neuromodulation
cannot be read off an inverse regression.

## Tests

From the repository root:

```matlab
run('matlab/tests/smoke_arsenal.m')            % bandpass_lfp, CSD
run('matlab/tests/smoke_ephys_methods.m')      % references, lead fields
run('matlab/tests/check_arsenal_identities.m') % CMR, CSD, Tikhonov identities
```

Synthetic checks cover output shapes, the CSD of a quadratic profile and
forward/inverse consistency. They do not validate electrode geometry,
conductivity or a physical lead field.

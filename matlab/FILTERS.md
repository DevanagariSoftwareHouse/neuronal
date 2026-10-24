# Layered `filter_*.m` family

The API separates frequency geometry, coefficient design, signal application,
decomposition, artifact treatment, spatial projection, and persistent storage.
It does not assume named neuronal bands. Existing `filter_bank_lfp`,
`filter_response`, `filter_compare`, `filter_probe`, and `filter_edge_mask`
remain compatible.

## Function map

| Layer | Functions | Contract |
|---|---|---|
| Frequency geometry | `filter_uniform`, `filter_dyadic`, `filter_logarithmic`, `filter_overlap` | O(1) count or one band; optional `'all'` materialization |
| Classical designs | `filter_design`, `filter_windowed_fir`, `filter_equiripple_fir`, `filter_butterworth`, `filter_chebyshev1`, `filter_chebyshev2`, `filter_elliptic` | Return a design record, not filtered samples |
| Application | `filter_causal`, `filter_forward_backward`, `filter_pad`, `filter_state` | Explicit boundary and state policy |
| Wavelet packets | `filter_wpt`, `filter_modwpt`, `filter_modwpt_details` | Decimated coefficients, full-rate coefficients, reconstructed contributions respectively |
| Time-frequency and adaptive modes | `filter_cwt`, `filter_stft`, `filter_multitaper`, `filter_emd`, `filter_vmd` | Distinct coefficient/PSD/mode outputs; see each help block |
| Artifacts | `filter_line_regression`, `filter_spectrum_interpolation`, `filter_zapline`, `filter_despike`, `filter_robust_detrend` | Explicit assumptions; no automatic method substitution |
| Spatial operations | `filter_rereference`, `filter_ssd`, `filter_joint_decorrelation`, `filter_csd` | Reference choice, projections or physical CSD |
| Derived representations | `filter_analytic`, `filter_power`, `filter_phase` | Analytic voltage, squared modulus, wrapped radians |
| Persistence | `filter_write`, `filter_open`, `filter_read` | Immutable typed binary artifact plus manifest and indexed mmap reads |

## Geometry has the interval-family calling convention

```matlab
n = filter_dyadic(500,3,.5);         % 15 complete bands
b = filter_dyadic(500,3,.5,2);       % one struct, no signals allocated
all_bands = filter_dyadic(500,3,.5,'all');
d = filter_butterworth(500,[b.low b.high],4);
y = filter_forward_backward(x,d);
```

Indices are 1-based. Linear overlap is the fraction of the actual interval
width shared by neighbors: hop = width*(1-overlap). Only complete intervals
are returned; a hop that does not divide the available span leaves a tail.
At overlap 0, a uniform/dyadic level partitions all of [0, Nyquist].
Logarithmic overlap is measured in log2 frequency and excludes DC.
Generator bounds are requested geometry, not brick-wall transfer functions.
DC-to-Nyquist selects identity; the edge bands select lowpass and highpass.

## Design and application

All ordinary signals are **samples by channels**. Vector input preserves
orientation in temporal filtering and artifact functions (except explicitly
matrix-oriented spatial/decomposition APIs). The common numerical path uses
CPU double, including for Wavelet Toolbox R2019a compatibility.

IIR designs use zero/pole/gain to SOS conversion; high-order transfer
polynomials are not formed. Bandpass IIR order is twice the prototype order.
FIR order must be even. Equiripple design requires `TransitionHz`; its band
edges are passband edges, whereas Chebyshev II uses stopband edges. Matching
order and nominal edges does not match response across methods.

```matlab
d = filter_equiripple_fir(500,[8 20],200,'TransitionHz',3);
[y1,state] = filter_causal(x(1:1000,:),d);
[y2,state] = filter_causal(x(1001:end,:),d,state);
```

The concatenation equals one causal call on the complete record. State
records reject a different design or channel count. Forward/backward filtering
uses MATLAB `filtfilt` and squares the interior magnitude response. It needs
the entire selected record in RAM. Calling it independently on chunks changes
the answer. `filter_pad` provides explicit padding and cropping indices; adding
it before `filtfilt` is an additional policy, not a replacement for the backend's
own boundary processing. Evaluate edge validity on the actual signal.

`filter_response` remains the existing b/a inspection API. For an SOS design,
evaluate each section with `freqz` and multiply section responses and gain;
do not collapse a delicate high-order IIR into b/a merely for visualization.

## Representation and method limits

- WPT coefficients are cells in ascending nominal frequency order, with
  Gray-code tree positions recorded. Decimation and extension change their
  time grid and lengths. MODWPT coefficients and MODWPT details are distinct;
  only terminal details are tested for additive voltage reconstruction.
- CWT returns complex coefficients plus its frequency axis and cone of
  influence. STFT returns unnormalized windowed FFT coefficients. Multitaper
  returns one-sided PSD/Hz using the existing `multitaper_spectrogram` helper.
- EMD/VMD modes are data-dependent and cannot be pooled by mode number as if
  they were fixed bands. All decomposition calls are in-memory.
- Line regression fits stationary sinusoids jointly with an intercept and
  preserves the fitted intercept. It can remove genuine activity exactly at
  the nominated frequency too.
- Spectrum interpolation replaces FFT magnitudes, retains phase, and enforces
  conjugate symmetry. It assumes periodic whole-record boundaries. It is a
  documented variant, not a claim of exact replication of Leske & Dalal.
- Despiking interpolates explicitly indexed sample neighborhoods, returning a
  replacement mask. It rejects unbracketed boundary gaps. It is not the Zanos
  generative removal method and cannot guarantee removal of prior lowpass
  smearing of spikes.
- Robust detrending is Huber IRLS polynomial regression with MAD scale, not
  an alias for the complete NoiseTools robust preprocessing pipeline.
- SSD averages explicitly supplied noise-band covariances and projects the
  centered broadband input. Ridge and fitted means are recorded. Fit on clean
  data and assess edge sensitivity; the first implementation includes the
  backend's boundary-affected samples in its covariance estimate.
- CSD is a one-dimensional second derivative with unequal-depth support,
  homogeneous conductivity, volts and meters as inputs, A/m^3 as output.
  It returns only interior contacts. It is neither iCSD nor kernel CSD.

## Dependencies and R2019a

| Functions | Dependency |
|---|---|
| Classical designs, filtfilt, analytic, multitaper, EMD | Signal Processing Toolbox |
| WPT, MODWPT/details, CWT | Wavelet Toolbox |
| VMD | MATLAB `vmd`, introduced R2020a; explicit dependency error on R2019a |
| ZapLine | Original NoiseTools `nt_zapline` and its dependencies, installed by the user |
| Geometry, basic artifacts/spatial operations, STFT, persistence | Base MATLAB |

No toolbox or external code is silently downloaded. No numerical GPU support
is claimed. `filter_zapline` is an adapter to the original algorithm, not
Zapline-plus. External backends retain their own licenses.

## Typed binary persistence

```matlab
metadata = struct('representation','voltage','units','uV', ...
    'source','00018/lfp_1/channel_7','configuration',d,'fs',500);
filter_write('derived/00018/ch007/band002',y,metadata,'single');
[map,m] = filter_open('derived/00018/ch007/band002');
segment = map.Data.real(1:500,1);
```

Each new folder contains `data.bin` and `manifest.mat`. The manifest records
shape, single/double precision, little-endian byte order, complex status,
expected bytes and user metadata. Complex artifacts store contiguous real
then imaginary planes. `filter_read` reassembles only the requested indices.
Voltage, complex coefficients, power, phase and source density have explicit
representation tags; supply correct units, axes, channel IDs, source identity
and the full processing configuration. Power is squared magnitude, not
automatically calibrated PSD. Zero-amplitude phase is NaN.

Artifacts cannot overwrite existing destinations. Writes stage in a temporary
directory and rename after successful binary close and manifest save. Use
exactly one writer per destination; this is not a distributed locking/cache
system. Byte-count checks detect truncation, not arbitrary bit corruption.
There is no automatic fingerprint, resume scheduler, compression, or full-bank
materialization. Memory mapping enables reuse; it does not reduce transform
working memory. For channels-by-samples CON2PHYS maps, transpose the selected
channel before filtering rather than copying all channels.

## Validation

Run `test_filter_family` after adding `matlab/tests` and `matlab/path`.
The repository scientific suite discovers it automatically. It tests geometry,
state continuity, pass/reject behavior, row/matrix shapes, line suppression,
known polynomial CSD, generalized-eigenvector invariants, transform contracts,
binary round trips and truncated-file rejection. Wavelet numerical tests run
when that toolbox is available; missing optional backends are explicit.
MATLAB R2019a runtime execution is distinct from syntax/lint validation.

## References and backend documentation

- Widmann et al. (2015), digital filter design: https://doi.org/10.1016/j.jneumeth.2014.08.002
- de Cheveigne & Nelken (2019), filter effects: https://doi.org/10.1016/j.neuron.2019.02.039
- Bruns (2004), Fourier/Hilbert/wavelet comparison: https://pubmed.ncbi.nlm.nih.gov/15262077/
- Coifman & Wickerhauser (1992), wavelet packets: https://doi.org/10.1109/18.119732
- Thomson (1982), multitaper: https://doi.org/10.1109/PROC.1982.12433
- Leske & Dalal (2019), spectrum interpolation: https://pmc.ncbi.nlm.nih.gov/articles/PMC6456018/
- de Cheveigne (2020), ZapLine: https://doi.org/10.1016/j.neuroimage.2019.116356
- de Cheveigne & Arzounian (2018), robust preprocessing: https://pmc.ncbi.nlm.nih.gov/articles/PMC5915520/
- Nikulin et al. (2011), SSD: https://pubmed.ncbi.nlm.nih.gov/21276858/
- de Cheveigne & Parra (2014), joint decorrelation: https://doi.org/10.1016/j.neuroimage.2014.05.068
- Dragomiretskiy & Zosso (2014), VMD: https://doi.org/10.1109/TSP.2013.2288675
- MathWorks: https://www.mathworks.com/help/signal/ref/vmd.html
- MathWorks: https://www.mathworks.com/help/wavelet/ref/modwpt.html
- MathWorks: https://www.mathworks.com/help/wavelet/ref/modwptdetails.html
- NoiseTools: http://audition.ens.fr/adc/NoiseTools/

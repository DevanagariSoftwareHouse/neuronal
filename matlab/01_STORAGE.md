# Neuronal raw storage: MATLAB BIN catalog v1

[Índice](README.md) · [Anterior](00_CONVENTIONS.md) · [Próximo](02_PREPROCESSING.md)

A first local backend for normalized electrophysiology datasets. It uses
headerless little-endian .bin files and a persistent MATLAB catalog.mat.
Cloud storage and NWB export are future work. This is the entry point of
the analysis order: every later chapter starts from a bounded block read
here ([00_CONVENTIONS.md](00_CONVENTIONS.md)).

## Primer: a numeric array needs a scientific description

The storage question is: “Can I retrieve the intended channel and time
interval without changing its meaning?” A binary file contains values, but
its bytes do not identify sampling rate, units, electrode order, or clock
origin. The descriptor and acquisition metadata supply that interpretation.
Matching byte counts establishes structural consistency, not correct units
or correct channel identities.

For $N$ samples, $C$ channels and $b$ bytes per value, an uncompressed matrix
occupies $NCb$ bytes. With MATLAB column-major samples-by-channels storage,
sample $k$ of channel $c$ begins at the zero-based byte offset

$$
o(k,c)=b\big[(k-1)+N(c-1)\big].
$$

This explains why a channel is contiguous on disk. The memory map makes
selective access possible; subsequent conversion to `double`, filtering,
or array construction can still allocate copies.

### Toy round trip with visible channel identities

This self-contained example uses a temporary file, and checks storage
ordering with base MATLAB `fread`. Production analysis should use validated
catalog descriptors and `neuronal_read`, as shown below.

```matlab
run('matlab/neuronal_startup.m')
original = single([11 12 13 14; 21 22 23 24]); % channels x samples
filename = [tempname '.bin'];
info = neuronal_write_binary(original, filename, 'SampleAxis', 2);
fid = fopen(filename, 'r', 'ieee-le');
assert(fid >= 0)
restored = fread(fid, info.shape, '*single');
fclose(fid);
assert(isequal(restored, original.'))
disp(restored(:,2)) % 21, 22, 23, 24: second channel
delete(filename)
```

### Carry the block origin into the next chapter

```matlab
% Prerequisites: m is a validated map; fs and event_s share its clock.
first = 1 + round(20*fs);
last = first + round(10*fs) - 1;
block = double(neuronal_read(m, first:last, 1:4));
origin_s = (first - 1)/fs;
local_event_s = event_s(:) - origin_s;
```

Keep `origin_s`, selected channel IDs, sampling rate, units and source
descriptor with every result. A waveform can look plausible even when a
20-second origin error aligns it to the wrong events. Confirm the absolute
timestamp origin from acquisition metadata before applying this conversion.

**Exercise.** Read the toy file as channels-by-samples without transposing
the stored layout. Explain why correct byte length does not catch this
mistake. For real CON²PHYS data, compare selected original and stored
samples from the beginning, middle and end of each channel before relying
on the normalized files.

## Public functions

| Function | Role |
| --- | --- |
| `neuronal_write_binary` | Write a numeric matrix as headerless little-endian BIN through a validated temporary file; `'SampleAxis',2` stores channels x samples input as samples x channels without a transpose |
| `neuronal_validate_file` | Check a descriptor's schema, byte length and host endianness (storage, not scientific equivalence) |
| `neuronal_register` | The single writer of `catalog.mat`: validate entries and publish or `'Replace'` a dataset alias |
| `neuronal_catalog` | Load the metadata catalog only, from a directory or a `.mat` path |
| `neuronal_file_path` | Resolve a descriptor path against the repository root or an explicit `Root` |
| `neuronal_memmap` | Read-only `memmapfile` with exactly the declared shape; one per `parfor` worker |
| `neuronal_read` | Read selected samples x channels (1-based) from a map without loading the file |

## Filesystem layout

~~~text
data/
  source/con2phys/01/        Original MAT / XLSX (unchanged)
  source/con2phys/02/...
  raw/00001/                 Normalized numeric data
    lfp_1.bin
    lfp_2.bin
    lfp_3.bin
    spike_time.bin
    spike_cluster.bin
    waveforms.bin
  raw/00002/...
  neuronal/catalog.mat       One struct entry per dataset
digest/+con2phys/digest.m
matlab/path/neuronal_*.m
~~~

Each catalog(k) represents a dataset; catalog(k).data(j) a recording;
catalog(k).data(j).file(f) a binary array descriptor containing path,
shape, dtype, endian, sampling_rate_hz, source, and spatial metadata.

In CON2PHYS the input LFP has channels x samples; the standardized output
has samples x channels in MATLAB column-major order. Each channel is
physically contiguous. Spike times and clusters are stored separately in
aligned vectors. Mean waveforms are stored as samples x units.
Original brain_areas and XLSX trial values are retained as metadata.

The ordering deep-to-superficial is stored; coordinates remain NaN until a
real site-to-channel mapping is available. The nominal 20 um pitch must NOT
be substituted for validated electrode coordinates. The temporal origin
is similarly NaN pending confirmation.

## Run from the repository root

~~~matlab
run('matlab/neuronal_startup.m')

entries = con2phys.digest('data/source/con2phys','data/raw', ...
    'Animals',1:18,'RecordStart',1);
catalog = neuronal_register('data/neuronal/catalog.mat', ...
    'con2phys','digest/+con2phys/digest.m',entries);

m = neuronal_memmap(catalog(1).data(1).file(1));
x = neuronal_read(m,1:5000,7); % 10 s at 500 Hz, seventh channel
clear m
~~~

Absolute source/output paths also work. Relative file descriptor paths are
resolved relative to the neuronal repository root by default, not MATLAB pwd,
or relative to an explicitly passed Root argument. The ingest refuses to
overwrite output files by default. To re-ingest, choose a new rawRoot or pass
'Overwrite',true. Each output is written first to a same-directory temporary
file and size-checked, then moved to its final name. The catalog is published
only after every descriptor passes schema/file length/endianness validation.

Never execute two digests targeting the same output folder concurrently.
There is not yet whole-dataset rollback or cryptographic hash comparison.
Do not discard the original files until round-trip scientific validation
of each dataset has been completed.

## From storage to analysis

~~~matlab
d = catalog(1).data(1).file(1);
m = neuronal_memmap(d);
fs = d.sampling_rate_hz;
block = neuronal_read(m, 1:60*fs, 1:4);          % samples x channels, stored class
x = double(block(:,1));                           % one channel for spectra (05)
lfp_cs = double(block).';                         % channels x samples for 02 and 06
seg = event_aligned_segments(block, stim_s, fs, [-.5 .5], [], 'SampleDim', 1);
~~~

Reading `m.Data.x` directly loads the whole array; `neuronal_read` indexes
only the requested window. The stored layout is samples x channels, while
referencing and CSD functions take channels x samples: transpose blocks,
never full recordings ([02_PREPROCESSING.md](02_PREPROCESSING.md),
[06_EVENT_ALIGNMENT.md](06_EVENT_ALIGNMENT.md)).

## parfor

~~~matlab
d = catalog(1).data(1).file(1);
maps = parallel.pool.Constant(@() neuronal_memmap(d));
power = zeros(d.shape(2),1);
parfor ch = 1:d.shape(2)
    x = maps.Value.Data.x(:,ch);
    power(ch) = mean(x.^2);
end
delete(maps)
~~~

Maps must be local to workers. Raw files must be read-only; result writers
should use independent files per worker and consolidate after completion.

## Synthetic verification

~~~matlab
run('matlab/tests/test_neuronal_raw_storage.m')
~~~

This synthesizes an animal's three MAT LFP files, spikes, clusters,
waveforms, brain area metadata, and XLSX trials. It tests binary roundtrips,
shape, catalog registration, duplicate guards, and size corruption.
MATLAB is required; validation against the 18 real animals is still pending.

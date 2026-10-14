# Neuronal raw storage: MATLAB BIN catalog v1

A first local backend for normalized electrophysiology datasets. It uses
headerless little-endian .bin files and a persistent MATLAB catalog.mat.
Cloud storage and NWB export are future work.

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
matlab/path/+con2phys/digest.m
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
    'con2phys','matlab/path/+con2phys/digest.m',entries);

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

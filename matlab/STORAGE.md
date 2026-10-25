# Storage family (MATLAB R2019a)

`matlab/path/storage_*.m` provides a common persistence API. There is one
artifact per logical key. Temporal windows should normally be **row selections
of a stored signal**, not additional keys, datasets, files, or directories.

## Quick start

```matlab
addpath('matlab/path');
st = storage_hdf5('root',fullfile(pwd,'data','derived','lfp_store'));
key = storage_key('session','18','area','lfp_1','channel',3,'frequency',7);
x = single(randn(100000,1)); % replace with an already filtered CPU signal
st = storage_write(st,key,x,'metadata',struct('fs',500,'band_hz',[4 12]));
segment = storage_read(st,key,[10001 20000]); % one-based, inclusive rows
info = storage_info(st,key);
keys = storage_list(st,'session_18');
```

Store samples in the first dimension, channels/other coordinates in the
remaining dimensions. A row vector has one row: `[1 1]` selects its entire row,
not its first sample. Convert single-channel signals with `x(:)` when intended.
Range reads preserve class and shape. Omit the range to read the whole artifact.
Empty ranges are invalid. Use the `first`/`last` indices produced by your interval
function, checking its endpoint convention before passing them to storage.
Filtering and interval generation remain separate operations.

## Constructors and defaults

| Constructor | Payload | Catalog | Defaults / restrictions |
| --- | --- | --- | --- |
| `storage_hdf5` | Chunked HDF5 `/data` | MAT sidecar | Nonempty, real dense numeric/logical arrays |
| `storage_binary` | Column-major raw binary | MAT sidecar | Real dense numeric/logical arrays, including empty arrays |
| `storage_mat` | MAT variable `x` | MAT sidecar | Dense numeric/logical, complex, struct, cell, char, string |
| `storage_sqlite` | MAT variable `x` | SQLite plus MAT sidecar | SQLite is an **index**, not numeric BLOB storage |
| `storage_hybrid` | HDF5 or binary | SQLite plus MAT sidecar | Choose `'array_backend','hdf5'` or `'binary'` |

All constructors forward name/value pairs to `storage_create(BACKEND,...)`.
`storage_create()` defaults to HDF5. Descriptors contain no live handles and can
be copied to workers. Every operation closes its own handles, including errors.
Each root belongs to one backend; use different roots when comparing backends.
SQLite/hybrid require Database Toolbox's native `sqlite` interface. No JDBC,
external service, or command-line SQLite executable is needed. Missing optional
support is an explicit error, never an automatic fallback.

| Option | Default | Meaning |
| --- | --- | --- |
| `root` | `pwd/data/derived` | Canonicalized once by the constructor |
| `readonly` | `false` | Reject create/write/append/delete/benchmark |
| `overwrite` | `false` | Existing writes fail unless explicitly enabled |
| `create_parents` | `true` | Create root and artifact parent directories |
| `precision` | `'preserve'` | Explicit `'single'`/`'double'` converts numeric input |
| `chunk_samples` | `65536` | HDF5 first-dimension chunk limit |
| `compression` | `0` | HDF5 deflate level 0–9; 0 disables deflate |
| `byte_order` | `'ieee-le'` | Binary payload byte order; also accepts `'ieee-be'` |
| `mat_version` | `'-v7.3'` | MAT serialization; also accepts `'-v7'` |
| `mat_compression` | `false` | MAT `-nocompression` by default |
| `array_backend` | `'hdf5'` | Hybrid payload backend only |
| `busy_timeout_ms` | `5000` | SQLite busy timeout per connection |

Options for other payload backends have no effect. HDF5 chunks have shape
`[min(N,chunk_samples),1,...,1]`, favoring one channel's contiguous samples.
Tune with measured workloads; these defaults are not claims of optimal speed.
HDF5 stores logical data as uint8 and restores logical class on read. Binary
logical values likewise use one byte. Integer types, including int64/uint64,
are preserved without passing through double. GPU arrays must be explicitly
`gather`ed. Sparse arrays and arbitrary top-level objects are rejected.

MAT `-v7` requires `mat_compression=true` for the R2019a contract. MAT `-v7.3`
range reads use `matfile` for numeric/logical arrays; records/text and v7 data
are loaded completely before selection. Binary range reads seek each trailing
column; whole-array reads use one sequential read. HDF5 reads selected chunks.

## Public API

| Function | Contract |
| --- | --- |
| `storage_defaults(backend)` | Return options without side effects |
| `storage_validate(st)` | Validate descriptor fields and values |
| `storage_create(backend,...)` | Initialize root/schema, without persistent handles |
| `storage_key(key)` | Validate relative logical key |
| `storage_key('session',id,...)` | Build canonical session/area/channel/frequency/filter/time coordinates |
| `storage_path(st,key)` | Return artifact/data/metadata/dataset/catalog locations |
| `storage_write(st,key,x,'metadata',struct(...))` | Persist complete artifact; return descriptor |
| `storage_read(st,key,[first last])` | Read all data or inclusive rows across other dimensions |
| `storage_append(st,key,x)` | Append rows with identical class/trailing dimensions |
| `storage_exists(st,key)` | Check payload/sidecar and, when applicable, catalog registration |
| `storage_info(st,key)` | Inspect class, shape, payload bytes, backend settings and user metadata |
| `storage_list(st,prefix)` | Sorted cell array of keys; optional exact key/subtree prefix |
| `storage_delete(st,key)` | Delete artifact and catalog registration; missing key is an error |
| `storage_flush(st)` | Synchronous API has no outstanding user-space buffers |
| `storage_close(st)` | Idempotent; descriptor stays reusable |
| `storage_capabilities(st)` | Supported operations and explicit performance/concurrency limits |
| `storage_benchmark(st,...)` | Isolated write/read/range benchmark with exact round-trip assertions |

Append is an explicit mutation even if `overwrite=false`. It reads the existing
array, concatenates in RAM, and replaces the complete artifact. It is **not
streaming append** and can require substantial RAM and temporary disk space.
Existing user metadata is retained; shape and byte counts are recomputed.
Partial updates are not implemented. `storage_capabilities` reports these limits.

## Layout, consistency and parallel workers

Each key maps to `artifacts/<key>.store/`, containing `data.h5`, `data.bin` or
`data.mat`, plus `metadata.mat`. Intermediate directories are shared. The
`.store` suffix is reserved in key components to prevent hierarchy collisions.
Absolute paths, traversal, empty components, backslashes and SQL punctuation
are rejected. Roots are trusted application-owned directories; do not insert
symlinks or edit payloads/sidecars by hand. `storage_info.bytes` counts only
the payload, not sidecars, filesystem allocation, or the SQLite catalog.

SQLite records key, backend, class, JSON shape, payload bytes and JSON user
metadata. Full metadata remains in the MAT sidecar (JSON is a searchable
projection and does not preserve every MATLAB type). `storage_list` uses the
catalog for indexed backends. Other backends enumerate sidecars. `exists` is
an existence check, not a checksum/integrity scan. Payload paths can be resolved
with `storage_path`; move the entire root, then reopen with its new path.

Writes stage complete payloads and sidecars before publication. Overwrite and
delete retain the old bundle until publication/catalog commit succeeds, then
remove it. Caught failures roll back the bundle and SQL transaction. Writers
acquire a root-level lock and fail with `storage:Locked` if another writer is
active. **Concurrent writes to the same root and reads overlapping a mutation
are unsupported.** Independent readers of a quiescent store are supported.
For `parfor`, give each worker an independent root/shard, or use one coordinated
writer. Do not share one HDF5 file among workers.

This is not a crash-atomic filesystem-plus-SQL transaction and does not provide
`fsync`/power-loss durability. After process termination, inspect temporary
bundles and catalog consistency before continuing. A `.storage-write-lock`
directory can remain after a crash: remove it only after confirming no writer
is active and checking incomplete publication. Metadata-only read access does
not load the full signal. The benchmark does not create production keys.

## Benchmark and tests

```matlab
st = storage_binary('root',fullfile(tempdir,'neuronal-binary-bench'));
r = storage_benchmark(st,'samples',1000000,'channels',4,'repeats',3);
disp(r)
addpath('matlab/tests');
test_storage_family
```

Benchmark results include metadata/catalog costs, report payload throughput in
MiB/s, and verify selected windows. OS caches are not evicted, so results are
not cold-disk measurements. Temporary benchmark stores are removed on success
or failure. Start small before testing session-sized arrays.

The contracts cover type preservation, inclusive multidimensional ranges,
append, overwrite, records/complex MAT data, endian order, empty binary arrays,
compression, safe keys, readonly access, failed-write preservation and cleanup.
SQLite/hybrid tests run when Database Toolbox is available and explicitly print
a skip otherwise. `.github/workflows/storage-family.yml` runs the suite using
the repository's self-hosted MATLAB R2019a runner.

MATLAB API references: [save](https://www.mathworks.com/help/matlab/ref/save.html),
[h5create](https://www.mathworks.com/help/matlab/ref/h5create.html),
[matfile](https://www.mathworks.com/help/matlab/ref/matfile.html),
[sqlite](https://www.mathworks.com/help/database/ug/sqlite.html).
SQLite statements use the R2019a-compatible `exec` API; newer MATLAB releases
may report its planned removal.

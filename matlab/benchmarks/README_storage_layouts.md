# neuronal storage-layout benchmark (MATLAB R2019a)

This is a standalone, non-destructive synthetic benchmark. It does not modify the `storage_*` API, nor write to datasets. Results use per-file `.part` → `.ready` rename or grouped `.ready` marker, with no live-reader assumption before publication.

```matlab
addpath('matlab/benchmarks');
root = '/home/gois/neuronal-storage-scratch';
mkdir(root);
r = benchmark_storage_layouts(root, ...
    'n_files',[100 1000 10000], ...
    'payload_bytes',[4096 1048576], ...
    'max_total_bytes',512*2^20);
```

The maximum bytes cap is **per case**. All synthetic test data are limited to dedicated unique test subdirectories. A CSV is saved in the benchmark root. Run on an NVMe outside Insync and ensure free space; comparison among filesystem/mount options requires running on each target filesystem separately. For robustness, compare results under cold/warm cache conditions. Results include page-cache effects and do not imply durability after power failure (`fclose`/rename are not `fsync`).

**Formats:** independent raw binary; independent raw binary with sparse sizing (not real `fallocate`); independent chunked HDF5; grouped chunked HDF5. Grouped HDF5 uses single writer by design. The benchmark does not test multi-process concurrency or claim parallel HDF5 write safety. HDF5 group creation is a single file, so `n_files` means logical results, not physical files for that case. Both HDF5 variants use uncompressed chunks, with no explicit fill values.

The content is single-precision test data with one non-NaN marker so readback detects empty files. Real `NaN` values are *not* a completion marker; publication must be tracked independently. No unverified ranking of formats is assumed.

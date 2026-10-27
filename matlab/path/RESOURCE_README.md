# Resource estimates and admission — MATLAB R2019a / Linux

The public estimate-first names are `estimate_resource` and `storage_estimate`. The `resource_*` helpers handle snapshots, scheduling and specialized internal estimators. All estimates are **heuristics**, not memory allocations, measured peaks, disk guarantees or cross-process locks.

## Resource estimates

`estimate_resource(N,...)` estimates a generic N-sample working set:

```matlab
req = estimate_resource(1675486,'precision','single', ...
    'workspace_factor',12,'gpu',false);
```

`estimate_resource(name,...)` dispatches named or function-handle models:

```matlab
req = estimate_resource(@filter_do,1675486,1,fd, ...
    'precision','double','phase','causal','device','cpu');
```

Models currently include `filter_do`, `spike_interval_plan` and `spike_interval_features`. The default for the filter estimator matches the causal default of `filter_do`. GPU input with a CPU fallback needs both RAM and VRAM budgets. For compatibility, named `storage_read` / `storage_write` calls still work, although `storage_estimate` is preferred.

## Storage estimates

`storage_estimate('read'|'write',shape,...)` describes the additional RAM and disk needs for dense real arrays, with `backend`, `precision`, `mat_version` and optional `range_rows`.

```matlab
write_req = storage_estimate('write',[1675486 28], ...
    'backend','binary','precision','int16');
read_req = storage_estimate('read',[1675486 28], ...
    'backend','mat','mat_version','-v7', ...
    'precision','int16','range_rows',[1 10000]);
```

Partial reads of MAT `-v7` use `load` and materialize the whole variable before slicing. `disk_bytes` approximates staged payload and metadata overhead, **not** the exact committed file size or space reserved by the filesystem. For actual available filesystem capacity and Linux I/O pressure, call `resource_storage(path,...)`.

## Inspect and schedule

- `resource_snapshot`: available RAM, load average (not CPU utilization), optional disk and GPU VRAM.
- `resource_storage`: filesystem capacity and Linux I/O pressure.
- `resource_admit`: check requested budgets against available capacity, reserve margins and caller-maintained `inflight` reservations.
- `resource_batch_size`: bound concurrency of identical tasks.
- `resource_wait`: timeout-bounded polling with pauses (no busy-spin).
- `resource_gpu_sync`: synchronize GPU work, not another process's VRAM allocation.

```matlab
s = resource_snapshot('gpu',false,'disk_path',tempdir);
inflight = struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',0);
[n,decision] = resource_batch_size(s,req,4, ...
    'ram_reserve',4*2^30,'inflight',inflight);
```

**Backwards compatibility:** `resource_estimate(N,...)` delegates to `estimate_resource(N,...)`; `resource_estimate_function(name,...)` remains as a dispatcher; `resource_estimate_storage_io(op,shape,...)` remains the low-level implementation. No existing call signatures need to change.

**Caveats:** `inflight` is not shared across MATLAB processes. Unknown requested capacity fails closed. GPU snapshots may initialize a context; call them on the MATLAB client. Do not wait while holding a storage lock. Calibrate heuristics with representative real workloads.

Tests (MATLAB R2019a): `addpath('matlab/tests'); test_resource_family; test_resource_estimate_function;`

# Resource utilities (MATLAB R2019a / Linux)

All `resource_*` tools are **advisory**. They do not reserve RAM, VRAM, or disk space, acquire inter-process locks, or guarantee memory peaks.

## Inspect and schedule

- `resource_snapshot`: system RAM, CPU load average (not utilization), available disk and optional GPU VRAM.
- `resource_storage`: filesystem capacity, closest existing ancestor and Linux I/O pressure (PSI).
- `resource_admit`: budgets after safety margins and caller-maintained `inflight` reservations. Unknown *requested* capacity fails closed.
- `resource_batch_size`: maximal identical-task concurrency using these budgets.
- `resource_wait`: timeout-bounded polling (no busy spin); GPU requests need `gpu=true`; disk requests need `disk_path`.
- `resource_gpu_sync`: GPU synchronization, **not** waiting for another process to free VRAM.

## Estimate by function

`estimate_resource(name,...)` is a public shorthand for `resource_estimate_function(name,...)`. Supported names: `filter_do`, `spike_interval_plan`, `spike_interval_features`, `storage_write`, `storage_read`. The generic `resource_estimate(N,...)` remains available.

`resource_estimate_filter_do` matches the causal default of `filter_do` and its `gpu='cpu'` fallback. A GPU-input CPU fallback must budget both RAM and VRAM. `resource_estimate_storage_io` models real dense arrays; partial MAT `-v7` reads load whole arrays, unlike binary ranges.

## Example

    addpath('matlab/path');
    req = estimate_resource('filter_do',1675486,1,fd,...
        'precision','double','phase','causal','device','cpu');
    s = resource_snapshot('gpu',false,'disk_path',tempdir);
    inflight = struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',0);
    [n,decision] = resource_batch_size(s,req,4,...
        'ram_reserve',4*2^30,'inflight',inflight);
    if n==0
        [s,decision] = resource_wait(req,'timeout',30,...
            'poll',0.25,'ram_reserve',4*2^30,'inflight',inflight);
    end

Input arrays are assumed resident unless otherwise documented. Disk estimates include a staging/metadata allowance but are not strict byte bounds. Calibrate memory multipliers empirically. Observe GPU on the MATLAB client, not each CPU worker. Independent MATLAB processes still need a separate inter-process lease manager. Never wait while holding storage locks.

Tests: `addpath('matlab/tests'); test_resource_family; test_resource_estimate_function;`

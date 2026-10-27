# Resource utility family (MATLAB R2019a / Linux)

Functions:
- `resource_snapshot`: host RAM, load average, disk free and optional selected-GPU VRAM.
- `resource_estimate`: heuristic per-task working-set estimate; calibrate multiplier using benchmarks.
- `resource_admit`: pure admission decision using budget margins and outstanding reservations.
- `resource_batch_size`: bound simultaneous identical tasks.
- `resource_wait`: cooperative polling, bounded by a timeout; no busy-spin.
- `resource_gpu_sync`: wait for outstanding GPU operations, **not** for VRAM availability.

## Example

```matlab
addpath('matlab/path');
s = resource_snapshot('gpu',false,'disk_path',tempdir);
r = resource_estimate(1675486,'precision','double','workspace_factor',12);
inflight = struct('cpu_bytes',0,'gpu_bytes',0,'disk_bytes',0);
[n,decision] = resource_batch_size(s,r,4,'ram_reserve',4*2^30,'inflight',inflight);
if n==0
    [s,decision] = resource_wait(r,'timeout',30,'poll',0.25, ...
        'ram_reserve',4*2^30,'inflight',inflight);
end
```

**Safety and scope**: checks and reservations are advisory and race-prone; these functions do not reserve RAM/VRAM, coordinate separate MATLAB processes, or guarantee OS/cgroup limits. The scheduling client must track `inflight` reservations when submitting and completing `parfeval` tasks. Do not wait holding a `storage_*` lock. GPU observation can initialize a GPU context and should not run on all CPU workers. If usable system RAM is unknown, admission fails closed. `cpu_load1` is load average, **not CPU utilization**. For cross-process coordination, use a separate atomic inter-process semaphore/lease manager. The disk snapshot is Java-based and optional.

Test: `addpath('matlab/tests'); test_resource_family`.

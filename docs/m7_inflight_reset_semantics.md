# M7 in-flight reset semantics (Phase C.5)

## Model A (admission-time authorization)

Source: `docs/decisions.md` D-002, `docs/revocation_models.md`.

> A transaction admitted under ALLOW retains its admission-time authorization
> through commit, even if policy later changes to DENY, unless a separate
> cancellation mechanism exists.

This IOPMP (`rtl/iopmp/iopmp.v`) latches address/write/data/RID/allow at
admission (`dma_gnt` with allow) and does **not** implement cancellation.

## Transaction landmarks (DMA path)

| Landmark | Observable meaning in this composition |
|----------|----------------------------------------|
| **REQUESTED** | `dma_master` asserts `req` into IOPMP (`dma_req`). |
| **ADMITTED** | IOPMP asserts `dma_gnt` **and** `txn_authorized_at_admission=1` (ALLOW path). DENY path also pulses `dma_gnt` with `txn_authorized_at_admission=0` and completes with `dma_error` without target access. |
| **TARGET_ACCEPTED** | Research arbiter accepts the IOPMP-forwarded request (`dma_gnt` from arbiter to IOPMP / entry to `S_MEM`). |
| **COMMITTED** | Protected SRAM `mem_changed` for the write (`protected_write_source=DMA`). |
| **COMPLETED** | IOPMP returns `dma_valid` to `dma_master` (success or error). |

## Transaction landmarks (CPU data path)

| Landmark | Observable meaning |
|----------|-------------------|
| **REQUESTED** | Ibex `data_req` for a research (normal/protect) address via adapter. |
| **GRANTED** | Adapter/arbiter grant (`cpu_gnt` / Ibex `data_gnt`). |
| **COMMITTED** | Protected SRAM `mem_changed` with `protected_write_source=CPU`. |
| **COMPLETED** | Ibex `data_rvalid`. |

## Test-only target delay

`m7_target_delay` may insert **N** cycles between arbiter `prot_req` and SRAM
access when `+TARGET_DELAY=N` (`N>0`). It:

* is deterministic;
* preserves address/write/data;
* does **not** change IOPMP authorization;
* is disabled (`N=0`) for normal directed tests unless an IF case requires it;
* is **instrumentation**, not a product feature.

## Attribution

`protected_write_source ∈ {CPU, DMA, NONE}` is derived from which master the
arbiter is serving when the SRAM commit pulse occurs — not from comparing
final data values alone.

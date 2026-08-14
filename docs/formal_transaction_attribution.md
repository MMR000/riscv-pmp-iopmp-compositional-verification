# Formal transaction attribution model (M3.5)

## Problem

Early M3 harness properties compared **live master inputs** (e.g. `cpu_privilege`) with **registered bus outputs** (`cpu_req_out`) or compared protected-memory equality naively. That produced false counterexamples classified as `FORMAL_HARNESS_BUG`.

## Method

Security properties attribute protected-memory effects to **admitted transactions** using metadata latched at admission time.

### PMP (CPU)

At authorized admission:

```text
hold_privilege  ← cpu_privilege
hold_write      ← cpu_write
hold_addr       ← cpu_addr
pending         ← 1
```

SP-02 is checked at **bus commit** (`pending && bus_valid`) for protected writes:

```text
hold_write && in_protected(hold_addr)  →  hold_privilege
```

### IOPMP (DMA)

Existing `hold_*` registers (`hold_authorized`, `hold_rid`, `hold_addr`, `hold_write`) are checked at **ST_PENDING bus commit** (`bus_valid`).

### Compositional (SP-10)

When `prot_mem_changed` on protected SRAM:

```text
(cpu_hold_write && hold_privilege)  OR  (dma_hold_write && hold_authorized)
```

Concurrent authorized DMA is allowed while an unauthorized CPU request is denied at admission.

## Assumptions

- FA-04: master inputs stable while `pending` / IOPMP non-IDLE.
- FA-07: synchronous clocking with documented reset warmup (`formal_helpers.vh`).

## Abstractions

- Single-word protected SRAM model (`DEPTH=256`) for integration proofs.
- Trusted boot configuration pulse in `formal_soc_tb` (FA-01).

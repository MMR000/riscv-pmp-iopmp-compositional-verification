# HARDWARE_READINESS_ARCHITECTURE_DECISION

## Decision: **Option A — Preserve historical C.5 architecture**

The evaluated C.5 top (`m7_ibex_c5_composed_top`) does **not** instantiate `rsdg` or any equivalent synthesizable fail-closed readiness gate.

- `sys_secure_ready` remains a **test-harness predicate**.
- IOPMP `!enable` is **fail-open** (`dma_allowed = 1`).
- `secure_ready` is unused unless `RSDG_COMMIT_EPOCH` is defined (not in C.5).

## Consequence for claims

Do **not** claim hardware-enforced fail-closed secure initialization for this C.5 design.

Readiness / configuration completeness is an **environmental / harness assumption**.

Standalone `rsdg.v` SP-11 formal results remain a **separate module-level experiment**, not wired into C.5.

## Option B status

A new hardware-gated C.5 candidate was **not** implemented in this round:

- Would require a new named design variant, full handshake validation, full C.5 regression, and new PPA scope.
- Historical J2/J3 measurements are **arbiter-scoped** and must not be transferred to a gated full system without a matched synthesis experiment.

No silent merge of RSDG into historical C.5.

# M4 minimality analysis — final evidence (M4B closure)

Internal research label only; not a novelty claim.

**Random campaign status:** `CORRECTED_FINAL` (`m4_random_v2`). Pre-fix results archived under `results/simulation/archive/`.

## Configuration matrix

| Config | Reset default | Admission gate (RSDG) | Pending/epoch | Verdict |
|--------|---------------|----------------------|---------------|---------|
| C0 | fail-open | no | no | **Insufficient** — SP-08/SP-13 counterexamples preserved |
| C1 | fail-closed | no | no | **Minimal sufficient** for reset-safety under modeled contract |
| C2 | fail-open | yes | no | Required only when fail-open reset is mandatory |
| C3 | fail-open | yes | epoch | Strong SP-12B contract; **not needed for reset-only safety** |
| C4 | fail-closed | yes | no | **Dominated by C1** — same security, extra gate logic |

## Latency / recovery limitation (fixture honesty)

The current abstract fixture measures **steady-state/control-path DMA latency** but **cannot** quantify realistic asynchronous/per-domain reset recovery latency because:

- recovery configuration is applied immediately after reset deassertion;
- the fixture uses a **single global `rst_n`** (no independent domain release);
- L1–L5 controlled recovery scenarios are **`BLOCKED_BY_FIXTURE`**.

Do not interpret `secure_ready_latency = 0` or `availability_block_cycles = 0` as proof of zero recovery cost. M5 with specification-aligned real IP is intended to measure realistic recovery.

## Per-configuration answers

### C0 — Why insufficient?

Fail-open IOPMP reset defaults permit protected-region DMA effects before `secure_ready` (RST-A counterexample preserved). Directed R7 (`iopmp_enable=0` bypass) and corrected random campaign reproduce `RESET_ASSUMPTION_DEPENDENCY` failures.

### C1 — What guarantee? What cost?

**Guarantee:** SP-08 RST-B **PROVED** (k-induction); SP-13 **PROVED**. Directed matrix: 0 security-relevant failures. Corrected random campaign: **0 genuine property counterexamples** (see `m4_configuration_comparison.csv`).

**Cost:** Yosys `m4_synth_top` — **36 cells vs C0 16 cells (Δ=+20)**, **1 `$adffe`** each. Normal-operation DMA write latency **10 cycles** (identical to C0).

### C2 — When needed? Cost?

**When:** Silicon/policy mandates fail-open IOPMP reset but pre-`secure_ready` admission must be blocked.

**Cost:** **26 cells (Δ=+10 vs C0)** — RSDG admission path logic.

### C3 — Stronger contract? Why unnecessary for reset?

**Contract:** SP-12B strict commit-time revalidation via `security_epoch`.

**Reset-only:** Global reset clears IOPMP FSM; epoch not required for reset semantics alone.

**Cost:** **34 cells (Δ=+18 vs C0)**.

### C4 — Benefit over C1?

**No measured security benefit** over C1 under reset contract. **43 cells (Δ=+27 vs C0)** — dominated by C1.

## CI-RESET final invariants (evidence-backed)

**CI-RESET-01A — Enforcement-before-effect:** A protected-region DMA memory effect requires IOPMP enforcement with valid security context.

**CI-RESET-01B — Admission gating:** Required for fail-open reset defaults (C2/C4 RSDG). Not required when fail-closed reset suffices (C1).

**CI-RESET-01C — Authorization-context continuity:** Required only for strict SP-12B (C3 epoch). Not required for Model A reset/recovery contract.

## Final minimal sufficient configuration

> **C1 (fail-closed IOPMP reset defaults)** is the least-complex sufficient configuration for the modeled reset-safety guarantee.

## Recommended M5

**A. Integrate specification-aligned IOPMP** — validate `iopmp_enable=0` bypass, per-domain reset, and realistic recovery latency against real IP.

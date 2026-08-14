# M7 Phase C.5 — In-Flight Reset Results

## Scope

Instrument and classify `RC-IF-01..03` on the real-Ibex compositional platform with
admission-time Model A landmarks. No PPA. Phase A/B/C evidence frozen.

## Instrumentation

- `m7_c5_event_monitor.sv` — cycle-stamped events (request/admit/deny/grant/commit/reset/secure_ready)
- `m7_target_delay.sv` — deterministic protected-path delay (`TARGET_DELAY=0` bypass for normal tests)
- `protected_write_source` attributed as `CPU` / `DMA` / `NONE` from arbiter serve bit (not data inference)

Landmarks: see `docs/m7_inflight_reset_semantics.md`.

## RC-IF-01 (DMA reset during in-flight)

| Subcase | Landmark | Result | Classification | Observation |
|---------|----------|--------|----------------|-------------|
| IF01-A | after REQUESTED, before ADMITTED | INCONCLUSIVE | INCONCLUSIVE | Admit window is zero-width for this IOPMP (admit same cycle as accepted request); race with reset |
| IF01-B | after ADMITTED, before TARGET_ACCEPTED | PASS | SIMULATION_EVIDENCE | Authorized DMA completes after DMA-domain reset (Model A drain) |
| IF01-C | after TARGET_ACCEPTED, before COMMITTED | PASS | SIMULATION_EVIDENCE | Same Model A completion after reset during delay |
| IF01-D | IOPMP/security reset after ADMITTED | PASS | SIMULATION_EVIDENCE | No auth data commit after IOPMP/security domain reset |

Interpretation: cancellation is **not** assumed. Observed behavior for B/C is admitted-transaction completion. Occasional extra same-data commit under delay is noted as harness/delay handshake sensitivity, not claimed as a security vulnerability.

## RC-IF-02 (CPU transaction + CPU reset)

| Subcase | Landmark | Result | Classification |
|---------|----------|--------|----------------|
| IF02-A | CPU prot request visible, before grant/delay | PASS | SIMULATION_EVIDENCE — one auth commit after reset (Model A) |
| IF02-B | after delay accept, before commit | PASS | SIMULATION_EVIDENCE — single `0xB0040004` commit |
| IF02-C | after commit, before response window | PASS | SIMULATION_EVIDENCE — commit before reset; no duplicate |

Safety check: one logical authorized store did not produce more than one auth commit in the IF02 campaign after holding the CPU through the observation window.

## RC-IF-03 (readiness milestones)

| Subcase | Setup | Result | Classification |
|---------|-------|--------|----------------|
| IF03-A RST-A | PMP_READY=1, IOPMP not configured | PASS | RESET_ASSUMPTION_DEPENDENCY (early unauth DMA allow) |
| IF03-A RST-B | same | PASS | SIMULATION_EVIDENCE (deny) |
| IF03-B | PMP_READY=0 (CPU held), IOPMP ready | PASS | SIMULATION_EVIDENCE (DMA deny under RST-B) |
| IF03-C | interconnect down | PASS | SIMULATION_EVIDENCE (no commit) |
| IF03-D | security_config reset after PMP_READY | PASS | SIMULATION_EVIDENCE |

PMP readiness does not gate DMA authorization; IOPMP/RST model does.

## Stale metadata

`STALE-01`: pre-reset RID=`0x01` DATA=`0x11111111`; post-reset RID=`0x02` DATA=`0x22222222` @ alt address → **DENY** (`SIMULATION_EVIDENCE`).

## Evidence

- Matrix: `results/tables/m7_inflight_reset_matrix.csv`
- Waveforms/logs: `results/m7/realcore_reset_c5/waveforms/`
- Semantics: `docs/m7_inflight_reset_semantics.md`

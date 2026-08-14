# M7 Phase C — real-core reset results

## Status

Directed RC-01..12: **PASS** (scientifically classified).  
Release-order sweep RC-ORD-A..F: **PASS** (functional recovery under fixed harness order).  
In-flight RC-IF-01..03: **INCONCLUSIVE** (not precisely instrumented).  
Random campaign: **100/100 PASS** (RST-A early unsafe counted as expected CE).

## Evidence tables

| Artifact | Path |
|----------|------|
| Directed + order + IF matrix | `results/tables/m7_realcore_reset_matrix.csv` |
| Random campaign | `results/tables/m7_realcore_reset_random.csv` |
| Latency raw | `results/tables/m7_realcore_reset_latency.csv` |
| Latency summary | `results/m7/realcore_reset/latency_summary.csv` |
| Preserved paper logs | `results/m7/realcore_reset/preserved/` |

## RC-01..12 summary

| ID | Model | Observed | Classification |
|----|-------|----------|----------------|
| RC-01 | RST-A | Early unauth DMA write reaches protected SRAM | RESET_ASSUMPTION_DEPENDENCY |
| RC-02 | RST-B | Early unauth DENY; sentinel retained | SIMULATION_EVIDENCE |
| RC-03 | RST-B | Early auth DENY, then ALLOW after TRUSTED_CFG | SIMULATION_EVIDENCE |
| RC-04 | RST-B | Post-recovery M-mode CPU write ALLOW | SIMULATION_EVIDENCE |
| RC-05 | RST-B | U-store fault `mcause=7`; memory unchanged | SIMULATION_EVIDENCE |
| RC-06 | RST-B | U-load fault `mcause=5` | SIMULATION_EVIDENCE |
| RC-07 | RST-B | Post-recovery auth DMA ALLOW | SIMULATION_EVIDENCE |
| RC-08 | RST-B | Post-recovery unauth DMA DENY | SIMULATION_EVIDENCE |
| RC-09 | RST-B | CPU held after cfg; unauth DMA still DENY | SIMULATION_EVIDENCE |
| RC-10 | RST-A | Partial IOPMP/sec reset → early unauth reachable | RESET_ASSUMPTION_DEPENDENCY |
| RC-11 | RST-B | Partial IOPMP/sec reset → unauth still DENY | SIMULATION_EVIDENCE |
| RC-12 | RST-B | U-fault `mcause=7` + auth DMA wins (`0xD00D00C7`) | SIMULATION_EVIDENCE |

## Blocking mechanism (RST-B)

Unauthorized / pre-config DMA is blocked by **IOPMP fail-closed defaults** under
`-DRST_B` (`iopmp_enable=1`, `rule0_valid=0` ⇒ no matching rule for the
protected region), not by a separate opaque `secure_ready` gate on the DMA
port. `sys_secure_ready` is an observability composition of firmware
`PMP_READY` and IOPMP config validity.

## Measured latency (real-core, raw then summary)

From `results/m7/realcore_reset/latency_summary.csv` (cycle deltas):

| Metric | min | median | mean | max |
|--------|-----|--------|------|-----|
| CPU release → PMP_READY | 100 | 100 | ~100.5 | 102 |
| IOPMP release → IOPMP_READY | 21 | 105 | ~97.6 | 107 |
| CPU release → secure_ready | 106 | 106 | ~106.2 | 108 |
| secure_ready → DMA req | 1 | 1 | ~1.1 | 2 |

These are **new real-core measurements**, not copied from abstract M7.

## Release-order sweep limitation

RC-ORD-A..F currently exercise post-recovery authorized DMA under the harness’s
default bring-up order (IC → sec/IOPMP → DMA, CPU with IC). They do **not** yet
fully permute independent domain release timings inside the RTL harness; stamps
are recorded for the implemented sequence. Treat as functional recovery
coverage plus stamp logging, not as a complete combinatorial reset-order proof.

## Scientific interpretation

- RST-A early access remains observable with real Ibex + DMA + IOPMP + MEM-RET →
  **RESET_ASSUMPTION_DEPENDENCY** (not a product vulnerability claim).
- RST-B directed behavior matches historical fail-closed intent →
  **SIMULATION_EVIDENCE**.
- Complementary to M5.10: abstract RST-B remains **FORMAL_PROOF** under its
  stated assumptions; real-Ibex RST-B is **not** claimed formally proved here.

## Complementary evidence statement (allowed)

> Abstract/model RST-B: FORMAL_PROOF under stated formal assumptions.  
> Real-Ibex composed RST-B: SIMULATION_EVIDENCE.

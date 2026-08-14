# Experiment log

## M1 baseline — PMP-only and PMP+IOPMP

| Field | Value |
|-------|-------|
| Date | 2026-08-10 |
| Commit | see `results/simulation/m1_summary.md` |
| Hypothesis | PMP blocks untrusted CPU but not DMA; adding IOPMP blocks unauthorized DMA |
| Configuration | Abstract CPU/DMA masters, simplified PMP and IOPMP, `bus_interconnect` |
| Method | Directed cocotb tests A1–A4, B1–B4, M1-CPU via `make m1` |
| Expected | PMP-only: CPU blocked, DMA reaches memory; PMP+IOPMP: both blocked when unauthorized |
| Actual | 9/9 PASS — see `results/simulation/m1_results.csv` |
| Interpretation | Baseline confirms **PMP-only system-level coverage limitation** for DMA; minimal IOPMP restores DMA mediation in this model |
| Next action | M2: concurrent access, boundary crossings, policy transitions |

## M2 — Boundary, concurrency, policy transitions, outstanding transactions

| Field | Value |
|-------|-------|
| Date | 2026-08-10 |
| Branch | `m2-compositional-isolation` |
| Starting commit | `b7b512607c50801a2b61a7e4a2a1a3f954c6a334` |
| Hypothesis | Simplified PMP+IOPMP satisfies documented SP properties under boundaries, concurrency, in-flight transactions, and dynamic policy changes under **Model A (admission-time authorization)** |
| Configuration | 3-stage IOPMP pipeline (admit → hold → pending), overflow-safe range check, CPU-priority interconnect, single outstanding transaction |
| Method | Directed tests B5–B9, M2-RANGE-ATOMICITY-01, C1–C10, PT1–PT5, RID1–RID5, M2-OUT-STALE-01, 200 seeded random scenarios via `make m2` |
| Expected | Complete-transfer containment; denied transfers have no protected-memory side effects; admitted transactions may complete after revoke; no SP-02/04/05/06/07/09/10 violations under Model A |
| Actual | 30/30 directed PASS; 200/200 random PASS; 0 security-property violations; 0 implementation bugs in observations table |
| Key findings | Range authorization at admission (not per-beat); PT3 admitted txn completes after revoke (EXPECTED_BY_MODEL); revocation visibility 1 cycle; completion latency ~6 cycles for admitted txn |
| Interpretation | Current design satisfies tested properties under Model A; Model B (immediate revocation) would require cancellation/quiescence — not implemented |
| Next action | M3: formal verification; review Model A vs B gap quantification |

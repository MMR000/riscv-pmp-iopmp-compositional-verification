# Evidence map

Maps major claims to public files. Frozen CSVs win if prose disagrees.

| Claim | Public evidence | Class |
|-------|-----------------|-------|
| CPU PMP denies protected U-mode accesses (`mcause` 5 / 7) | `results/tables/m7_ibex_pmp_matrix.csv`; Phase A logs under `results/m7/ibex/tests/` | `SIMULATION_EVIDENCE` |
| Ibex + DMA + IOPMP compose under directed scenarios (8/8) | `results/tables/m7_ibex_composed_matrix.csv` | `SIMULATION_EVIDENCE` |
| Composition scenario-sampling (100/100) | `results/tables/m7_ibex_composed_random.csv` | `SIMULATION_EVIDENCE` |
| RST-A exposes reset-assumption dependency (early unauthorized DMA reachability under fail-open init) | `results/tables/m7_realcore_reset_matrix.csv` (RC-01, RC-10); `results/tables/m7_inflight_reset_matrix.csv` (IF03-A RST-A); `results/tables/m7_realcore_release_order_matrix.csv` | `RESET_ASSUMPTION_DEPENDENCY` — not a vulnerability |
| RST-B remains fail-closed in real-core simulation across independent release orders | `results/tables/m7_realcore_release_order_matrix.csv`; `results/tables/m7_realcore_release_order_random.csv`; `results/tables/m7_realcore_reset_matrix.csv` RC-02+ | `SIMULATION_EVIDENCE` |
| Abstract RST-B / compositional guarantees under stated assumptions | `results/tables/m510_guarantee_matrix.csv`; `results/tables/m510_property_matrix.csv`; `results/tables/m510_assumption_sensitivity.csv` | `FORMAL_PROOF` on the **abstract** model — not full-Ibex proof |
| Real-core reset random campaign matched modeled expectations (100/100) | `results/tables/m7_realcore_reset_random.csv` | per-row class in CSV |
| Directed real-core reset RC-01..12 PASS; RC-IF-01..03 INCONCLUSIVE | `results/tables/m7_realcore_reset_matrix.csv` | mixed; IF tests `INCONCLUSIVE` |
| IF01-A INCONCLUSIVE (zero-width REQUESTED→ADMITTED window) | `results/tables/m7_inflight_reset_matrix.csv`; `docs/m7_inflight_reset_results.md` | `INCONCLUSIVE` |
| J2→J3 post-route area +0.36% at common 20 ns | `results/tables/m7_full_ibex_ppa_20ns_overhead.csv`; `results/tables/m7_journal_ppa_main.csv` | post-route physical-design evidence |
| Demonstrated Fmax J0/J1/J2/J3 | `results/tables/m7_journal_timing_summary.csv`; `results/tables/m7_full_ibex_fmax_sweep.csv` | post-route physical-design evidence |
| J1 Fmax anomaly | `docs/m7_j1_timing_anomaly_audit.md`; `results/tables/m7_critical_paths.csv` | `CAUSE_NOT_DEFINITIVELY_ESTABLISHED` |
| CPU/DMA performance landmarks | `results/tables/m7_journal_performance_summary.csv`; `results/tables/m7_realcore_performance.csv`; `results/tables/m7_dma_throughput.csv` | `SIMULATION_EVIDENCE` |
| M57-FP-04 / FIX-2 | `results/tables/m57_*.csv`; `results/tables/m58_*.csv`; `results/tables/m59_*.csv` | do **not** promote bounded rows to `FORMAL_PROOF` |
| Third-party stale-route (evaluated integration) | `results/tables/m56_route_freshness.csv`; `docs/m56_patch_description.md` | `RTL_IMPLEMENTATION_DEFECT` in that third-party integration — not an architectural IOPMP vulnerability |
| Evidence-level legend for reset | `results/tables/m7_reset_evidence_levels.csv` | meta |

Architecture (CPU PMP vs DMA IOPMP, no DMA-through-PMP): `docs/m7_ibex_composed_architecture.md`.

# Evidence map

Maps major claims to public files. Frozen CSVs win if prose disagrees. Cleanup package
`IEEE_Access_Final_Evidence_Cleanup.zip` (`7a91a075…`) supersedes conflicting earlier values.

| Claim | Public evidence | Class |
|-------|-----------------|-------|
| CPU PMP denies protected U-mode accesses (`mcause` 5 / 7) | `results/tables/m7_ibex_pmp_matrix.csv`; Phase A logs under `results/m7/ibex/tests/` | `SIMULATION_EVIDENCE` |
| Ibex + DMA + IOPMP compose under directed scenarios (8/8) | `results/tables/m7_ibex_composed_matrix.csv` | `SIMULATION_EVIDENCE` |
| Composition scenario-sampling (100/100) | `results/tables/m7_ibex_composed_random.csv` | `SIMULATION_EVIDENCE` |
| RST-A exposes reset-assumption dependency (early unauthorized DMA reachability under fail-open init) | `results/tables/m7_realcore_reset_matrix.csv` (RC-01, RC-10); `results/tables/m7_inflight_reset_matrix.csv` (IF03-A RST-A); `results/tables/m7_realcore_release_order_matrix.csv` | `RESET_ASSUMPTION_DEPENDENCY` — not a vulnerability |
| RST-B remains fail-closed in real-core simulation across independent release orders | `results/tables/m7_realcore_release_order_matrix.csv`; `results/tables/m7_realcore_release_order_random.csv`; `results/tables/m7_realcore_reset_matrix.csv` RC-02+ | `SIMULATION_EVIDENCE` |
| Abstract RST-B / compositional guarantees under stated assumptions | `results/tables/m510_guarantee_matrix.csv`; `results/tables/m510_property_matrix.csv`; `results/tables/m510_assumption_sensitivity.csv` | `FORMAL_PROOF` on the **abstract** model — not full-Ibex proof |
| Real-core reset random campaign matched modeled expectations (100/100) | `results/tables/m7_realcore_reset_random.csv` | per-row class in CSV; **distinct** from the 200-seed RAND-ORD campaign |
| Directed IF/STALE campaign (any-address IOPMP `dd7fe6…`) | `results/tables/m7_inflight_reset_matrix.csv`; `results/ieee_access_final/release_candidate/c5_full_regression_anyaddr.log` | `SIMULATION_EVIDENCE` except IF03-A RST-A |
| IF01-A **RESOLVED/PASS** 1/1/1, grant cyc 32, DMA SRAM write cyc 43, `0x600d00c1` | `results/tables/m7_if01_a_final_ledger.csv`; `results/ieee_access_final/release_candidate/IF01_A_events_final.log` | `SIMULATION_EVIDENCE` |
| Historical IF01-A INCONCLUSIVE (public v1) | `results/historical/public_v1_headline/m7_inflight_reset_matrix.csv`; `docs/history/IF01_A_HISTORICAL_INCONCLUSIVE.md` | historical only |
| Historical original IOPMP IF01-A duplicate (`a4d977…`, 2 grants / 2 writes) | `results/ieee_access_final/release_candidate/IF01_A_events_original_iopmp.log` | historical FAIL / negative control |
| IF02-A suite PASS, `sb_fail=0`, epoch-aware TXN_ID | `results/ieee_access_final/simulation/tests/IF02-A_RST-B.cleanup.log` | `SIMULATION_EVIDENCE`; historical SCOREBOARD_FAIL is monitor-only |
| IF03-C `err=NOT_ISSUED` PASS; IF03-D `err=0` PASS | cleanup IF03 logs under `results/ieee_access_final/simulation/tests/` | `SIMULATION_EVIDENCE` |
| Fixed ORD-A..H × RST-A/B (16/16) | `results/tables/m7_realcore_release_order_matrix.csv`; anyaddr copy in `results/ieee_access_final/release_candidate/` | RST-A `RESET_ASSUMPTION_DEPENDENCY`; RST-B `SIMULATION_EVIDENCE` |
| 200-seed RAND-ORD | 200 logs `results/m7/realcore_reset_c5/tests/RAND-ORD_s*.log`; CSV `results/tables/m7_realcore_release_order_random.csv` | do **not** merge with the 100-seed reset-random campaign; aggregate wall time `NOT_RECORDED` |
| J2/J3 final post-route area 277641 / 280331 (+0.97%) | `results/tables/m7_journal_ppa_main.csv`; `results/tables/m7_full_ibex_ppa_20ns_overhead.csv`; `results/ieee_access_final/ppa/` | post-route physical-design evidence, `FLOW_VARIANT=final_dd7fe6` |
| Historical J2/J3 279752 / 280749 (+0.36%) | `results/historical/public_v1_headline/` | superseded headline |
| Demonstrated Fmax J0/J1/J2/J3 | `results/tables/m7_journal_timing_summary.csv`; `results/tables/m7_full_ibex_fmax_sweep.csv` | post-route physical-design evidence (not re-run for final_dd7fe6) |
| SP-08 RST-B / ARB v2 / any-address no-regrant pinned stats | `results/ieee_access_final/formal/PROOF_STATISTICS.csv` | `FORMAL_PROOF`; SBY `--version` is `unknown SBY version` |
| Formal vs production arbiter | `results/ieee_access_final/arbiter_diff/FORMAL_VS_PRODUCTION_ARBITER.md` | FORMAL ports only; no synthesized functional difference |
| Option A C.5 architecture | `docs/history/OPTION_A.md`; `results/ieee_access_final/release_candidate/HARDWARE_READINESS_ARCHITECTURE_DECISION.md` | harness readiness; IOPMP fail-open |
| Standalone RSDG | `formal/sby/sp11_rsdg_prove.sby`; `results/formal/sp11_rsdg_prove/` | separate module experiment — not wired into C.5 |
| M57-FP-04 / FIX-2 | `results/tables/m57_*.csv`; `results/tables/m58_*.csv`; `results/tables/m59_*.csv` | do **not** promote bounded rows to `FORMAL_PROOF` |
| Third-party stale-route (evaluated integration) | `results/tables/m56_route_freshness.csv`; `docs/m56_patch_description.md` | `RTL_IMPLEMENTATION_DEFECT` in that third-party integration — not an architectural IOPMP vulnerability |
| Evidence-level legend for reset | `results/tables/m7_reset_evidence_levels.csv` | meta |

Architecture (CPU PMP vs DMA IOPMP, no DMA-through-PMP): `docs/m7_ibex_composed_architecture.md`.

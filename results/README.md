# Results index

Frozen compact evidence for the paper. Do not treat omitted build trees as missing science: the matrices and metrics below are the archival record.

Verify: `sha256sum -c results/FROZEN_EVIDENCE_MANIFEST.sha256`.

## M1 / M2

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m2_security_matrix.csv`, `tables/security_matrix.csv`, `simulation/` summaries | Early PMP-only vs PMP+IOPMP simulation | `SIMULATION_EVIDENCE` | `make m1`, `make m2` |

## M5.10 formal

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m510_property_matrix.csv`, `m510_guarantee_matrix.csv`, `m510_assumption_sensitivity.csv` | Abstract compositional guarantees / assumptions | `FORMAL_PROOF` / sensitivity as labeled | `make m510-matrix`, `make m510` |
| `m510/` | Environment notes, summaries | supporting | same |

Full-Ibex composition is **not** in this bucket.

## M7 Phase A

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m7_ibex_pmp_matrix.csv` | IBEX-PMP-01..08 | `SIMULATION_EVIDENCE` | `bash scripts/run/run_m7_phase_a.sh` |
| `m7/ibex/tests/*.log` | Per-test logs | supporting | same |

## M7 Phase B

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m7_ibex_composed_matrix.csv` | IBEX-COMP-01..08 | `SIMULATION_EVIDENCE` | `make m7-ibex-composed` |
| `tables/m7_ibex_composed_random.csv` | 100-seed campaign | `SIMULATION_EVIDENCE` | same analysis scripts |

Replay commands in the random CSV may contain historical absolute paths; use `$REPO_ROOT` locally.

## M7 Phase C

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m7_realcore_reset_matrix.csv` | Directed RST-A/B | `RESET_ASSUMPTION_DEPENDENCY` / `SIMULATION_EVIDENCE` / `INCONCLUSIVE` as labeled | `make m7-ibex-reset` |
| `tables/m7_realcore_reset_random.csv` | 100 seeds vs model | per-row | same |
| `tables/m7_realcore_reset_latency.csv` | Latency samples | supporting | same |

## M7 Phase C.5

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m7_inflight_reset_matrix.csv` | In-flight reset; IF01-A **RESOLVED/PASS** | mixed | `make m7-ibex-reset-inflight` |
| `tables/m7_if01_a_final_ledger.csv` | Independent 1/1/1 ledger `0x600d00c1` | `SIMULATION_EVIDENCE` | same |
| `ieee_access_final/` | Cleanup + RC logs, final proofs, J2/J3 `final_dd7fe6` | supporting | n/a |
| `historical/public_v1_headline/` | Superseded IF01-A INCONCLUSIVE + D.3 PPA | historical | n/a |
| `tables/m7_realcore_release_order_matrix.csv` | 16 deterministic orders | mixed | `make m7-ibex-release-orders` |
| `tables/m7_realcore_release_order_random.csv` | 200 seeds | mixed | same |
| `tables/m7_reset_evidence_levels.csv` | Evidence-level legend | meta | n/a |

## M7 Phase D / journal PPA

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m7_journal_ppa_main.csv`, `m7_full_ibex_ppa_20ns.csv`, `m7_full_ibex_ppa_20ns_overhead.csv` | Common 20 ns SKY130HD post-route area; headline J2=277641 J3=280331 +0.97% (`final_dd7fe6`) | open-source RTL-to-GDS estimate | `FLOW_VARIANT=final_dd7fe6` J2/J3 rerun |
| `tables/m7_journal_timing_summary.csv`, `m7_full_ibex_fmax_sweep.csv`, `m7_critical_paths.csv` | Demonstrated Fmax / stress / paths | same; J1 cause not definitive | same |
| `m7/ppa_full/orfs/J*/metrics*.json`, `fairness_check*.md` | Compact physical-design metrics | supporting | same |

10 ns rows are a high-frequency **stress point**, not the main area comparison.

## Performance

| Files | Meaning | Class | Regenerate |
|-------|---------|-------|------------|
| `tables/m7_journal_performance_summary.csv`, `m7_realcore_performance.csv`, `m7_dma_throughput.csv` | CPU/DMA landmarks; sequential DMA N=16/64/256 | `SIMULATION_EVIDENCE` | `make m7-performance` |

## Figures

`figures/pdf/`, `figures/svg/`, generator `scripts/figures/generate_journal_figures.py`. See `docs/FIGURES.md`.

## M5–M5.9 tables

`tables/m5_*.csv` through `m59_*.csv`: external IOPMP / FIX-2 / formal environment ladder. Bounded rows stay `BOUNDED_EVIDENCE`. Stale-route: `RTL_IMPLEMENTATION_DEFECT` of the evaluated third-party integration.

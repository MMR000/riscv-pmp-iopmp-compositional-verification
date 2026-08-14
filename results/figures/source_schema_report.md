# Source schema report (M7 journal figures)

Generated from frozen CSVs. No values were invented.

| source file | columns | rows | evidence | plot? | used by |
|---|---|---:|---|---|---|
| `results/tables/m7_journal_ppa_main.csv` | `variant, description, clock_period_ns, cells, post_route_area, area_overhead_vs_J0_pct, core_area, setup_wns_ns, hold_wns_ns, route_drc, gds` | 4 | Final common 20 ns PPA (cells, post-route area, WNS). | yes | Q1,Q2,Q4-area |
| `results/tables/m7_full_ibex_ppa_20ns.csv` | `variant, description, ibex_commit, orfs_commit, orfs_image_digest, platform, clock_period_ns, flow_variant, memory_policy, lec_check, synth_cells, synth_comb_cells, synth_seq_cells, synth_area, place_area, route_area, core_area, die_area, utilization, buffer_count, inverter_count, wirelength, setup_wns_ns, setup_tns_ns, hold_wns_ns, hold_tns_ns, timing_pass, route_drc, gds_generated, runtime_s, peak_memory_mb, result, notes` | 4 | Full 20 ns physical metrics; corroborates journal main. | yes | cross-check Q1/Q2 |
| `results/tables/m7_full_ibex_ppa_20ns_overhead.csv` | `comparison, metric, baseline, variant, raw_delta, pct_delta, notes` | 20 | Incremental 20 ns deltas (cells/area/core/buffers/WL). | yes | Q3 |
| `results/tables/m7_full_ibex_ppa_overhead.csv` | `comparison, metric, baseline, variant, raw_delta, pct_delta, notes` | 17 | D.2 mixed 10 ns overhead; not the final comparison. | no (wrong clock mix) | do not mix with Q1–Q3 |
| `results/tables/m7_full_ibex_fmax_sweep.csv` | `variant, period_ns, setup_wns_ns, setup_tns_ns, hold_wns_ns, hold_tns_ns, route_result, route_drc, gds, timing_pass, result, notes` | 18 | Per-period full-flow WNS/route/timing results. | yes | Q5 |
| `results/tables/m7_journal_timing_summary.csv` | `variant, result_10ns, shortest_demonstrated_pass_ns, demonstrated_fmax_mhz, critical_path_category` | 4 | Demonstrated Fmax + 10 ns stress status. | yes | Q4 |
| `results/tables/m7_critical_paths.csv` | `variant, period_ns, flow_variant, notes, path_group, slack_ns, data_arrival_ns, data_required_ns, startpoint, endpoint, critical_path_category, through_pmp, through_iopmp, through_dma, through_reset_sec, through_alu_adder, ff_q_delay_ns, hierarchy_hint, cell_types, report` | 10 | Worst setup path category/slack/arrival; PMP flags. | yes | Q6 |
| `results/tables/m7_realcore_performance.csv` | `test_id, metric, cycles, source, classification, notes` | 14 | CPU/DMA directed latency and throughput pointers. | yes | Q7,Q8 |
| `results/tables/m7_journal_performance_summary.csv` | `metric, value, notes` | 13 | Compact performance scalars. | yes | cross-check Q7–Q10 |
| `results/tables/m7_dma_throughput.csv` | `n, first_request_cycle, last_completion_cycle, total_cycles, transfers_per_cycle, cycles_per_transfer, classification, notes` | 3 | Measured cycles/transfer for N=16/64/256. | yes | Q9 |
| `results/tables/m7_realcore_reset_latency.csv` | `test_id, metric, cycles, reset_model` | 46 | Directed reset recovery samples (mostly RST-B). | yes | Q11 |
| `results/tables/m7_realcore_release_order_latency.csv` | `test_id, reset_model, metric, cycles` | 2052 | ORD + RAND-ORD latency landmarks (2052 rows). | yes | not plotted as Q13 x=seed |
| `results/tables/m7_realcore_release_order_matrix.csv` | `test_id, reset_model, cpu_release_cycle, dma_release_cycle, iopmp_release_cycle, security_config_release_cycle, interconnect_release_cycle, pmp_ready_cycle, iopmp_ready_cycle, secure_ready_cycle, first_dma_legal_issue_cycle, early_dma_request_cycle, early_dma_result, early_dma_commit_cycle, post_ready_unauth_dma_result, post_ready_auth_dma_result, cpu_u_access_result, cpu_mcause, memory_before, memory_after, expected, observed, classification, result, notes` | 16 | ORD-A..H × RST-A/B early-access outcomes. | yes | Q12 |
| `results/tables/m7_realcore_release_order_random.csv` | `seed, reset_model, cpu_release, dma_release, iopmp_release, sec_release, ic_release, early_dma_result, result, classification, observed, observed_expected_counterexample, unexpected_failure, replay` | 200 | 200-seed early-access campaign; no latency column. | yes | Q13 |
| `results/tables/m7_inflight_reset_matrix.csv` | `test_id, reset_model, target_delay, admit_cycle, commit_cycle, reset_cycle, memory_before, memory_after, commit_source, cpu_mcause, observed, classification, result, notes` | 13 | In-flight reset cases including INCONCLUSIVE. | yes | not a CORE figure |
| `results/tables/m7_reset_evidence_levels.csv` | `evidence_level, artifact, claim_class, notes` | 6 | Six evidence layers with recorded claim classes. | yes | Q14 (layer list, not claim matrix) |
| `results/m7/performance/raw_samples.csv` | `seed, metric, cycles` | 1000 | 500 auth + 500 deny DMA latencies. | yes | Q10 |

## Notes

- `m7_full_ibex_ppa_overhead.csv` is D.2 10 ns / mixed-route evidence and is **not** used for Q1–Q3.
- `m7_reset_evidence_levels.csv` does **not** contain a claim×layer matrix; Q14 plots the six recorded layers only.
- `m7_realcore_release_order_random.csv` has no `secure_ready` latency; Q13 uses early-access outcome vs seed.
- RAND-ORD latencies exist in `m7_realcore_release_order_latency.csv` but lack a seed join key, so they are not merged into Q13.


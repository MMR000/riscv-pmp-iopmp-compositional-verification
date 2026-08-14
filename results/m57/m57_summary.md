# Milestone M5.7: PARTIAL

## 1. Starting HEAD

`096a984`

## 2. M5.6 commit

`096a984` — m5.6: repair IOPMP AXI write transaction binding

## 3. M5.6 tag

`checkpoint-m56-write-path-repair`

## 4. Branch

`m57-fullrtl-formal-validation`

## 5. Final HEAD

(uncommitted at report generation; run `git rev-parse HEAD` after M5.7 commit)

## 6. Formal harness bug root cause

M5.6 abstract harness (`formal_m56_write_path_tb.sv`) modeled a simplified FSM and checked combinational `dst_aw_valid` unrelated to initiator handshakes. Step-1 F-WP counterexample classified **FORMAL_HARNESS_BUG** (`HARNESS_ABSTRACTION`, `PROPERTY_ENCODING`). See `docs/m57_formal_harness_bug_analysis.md`.

## 7. New formal architecture

`formal/harness/formal_m57_fullrtl_write_path_tb.sv` instantiates real `rv_iopmp_data_abstractor_axi` (with internal `axi_demux` + `axi_err_slv`). Shared FIX-0/FIX-2 via `-DM57_VARIANT_ORIGINAL` / `M57_VARIANT=original|proper`. Primary checker: Verilator `--assert` on directed auth→deny stimulus. Secondary: SymbiYosys BMC (blocked at Yosys elaboration).

## 8. RTL variants tested

| ID | Overlay | Path |
|----|---------|------|
| FIX-0 | original | `m56/rtl/original/rv_iopmp_data_abstractor_axi.sv` |
| FIX-2 | proper | `m56/rtl/proper/rv_iopmp_data_abstractor_axi.sv` |

## 9. Formal assumptions

M57-FA-01..09 documented in `docs/m57_formal_assumptions.md`.

## 10. Formal property matrix

`results/tables/m57_pre_post_formal_matrix.csv`

| Property | Original | Proper |
|----------|----------|--------|
| M57-FP-04 | COUNTEREXAMPLE | BOUNDED_PASS |
| M57-FP-02/03/15 | COUNTEREXAMPLE | BOUNDED_PASS |
| SymbiYosys BMC | INCONCLUSIVE | INCONCLUSIVE |

## 11. Original RTL counterexamples

- **Verilator directed**: M57-FP-04 fails at ~255 ns (auth→deny sequence); trace in `results/formal/m57/pre_fix_counterexamples/M57-FP-04_original_verilator.trace.txt`
- **Simulation replay**: `scripts/m57/replay_formal_trace.py` → **REPRODUCED_IN_RTL_SIMULATION** (`results/m56/before_fix/M56-BEFORE-CE.txt`)
- Classification: **EXPECTED_ORIGINAL_DEFECT**

## 12. Repaired RTL results

- Verilator assertions: **BOUNDED_PASS** on M57-FP-04/02/03/06/15 (directed auth then deny)
- No master `mem_write_event` on denied write with `route_select=0`
- SymbiYosys: **INCONCLUSIVE** (Yosys 0.68 SV frontend cannot elaborate vendor packages)

## 13. Cover / reachability

Harness cover properties + m56 campaigns recorded in `results/formal/m57_cover_results.csv`.

## 14. Assumption sensitivity

`results/tables/m57_assumption_sensitivity.csv` — weakening single-outstanding-write and IOPMP-grant bounds explored; central safety depends on M57-FA-05/07.

## 15. AW-before-W delay investigation

Delay=8 failure in M5.6 timing matrix reclassified **TESTBENCH_WATCHDOG_LIMIT** (not RTL deadlock). See `docs/m57_aw_w_delay_investigation.md` and `results/tables/m57_aw_w_delay_matrix.csv`.

## 16. Safety results

Safety properties checked on real RTL closure. Original exhibits reachable master W under denied grant context; proper blocks master W via latched `route_select_q` + phased AW/W gating.

## 17. Liveness results

M57-FP-08/09 addressed via M5.6 simulation regression (**BOUNDED_LIVENESS** only). No unbounded liveness proof.

## 18. Counterexample replay results

| Trace | Result |
|-------|--------|
| M5.6 before CE | REPRODUCED_IN_RTL_SIMULATION |
| M5.7 Verilator CE | preserved text trace |

## 19. Simulation regression

`results/tables/m57_regression_matrix.csv`: m55-baseline PASS, m56-regression PASS, m1 PASS, m2 PASS.

## 20. Lightweight synthesis

NOT_RUN

## 21. Paper interpretation

The original implementation admits a formally reachable (Verilator) and simulated trace where a denied write can still produce a downstream W handshake because W forwarding is not transaction-bound to the current IOPMP grant. The M5.6 repair eliminates this master-path W on the directed deny sequence under assumptions M57-FA-01..09. M5.6 abstract SymbiYosys result remains **non-evidence** for RTL.

## 22. Remaining limitations

- SymbiYosys BMC / induction not achieved (tool elaboration)
- Bounded Verilator evidence only (not PROVED)
- Denied-write source completion in M5.7 harness times out (error-slave path) though safety asserts pass

## 23. Reproduction commands

```bash
git checkout m57-fullrtl-formal-validation
make m57-verilator
make m57-regression
python3 scripts/m57/replay_formal_trace.py
python3 scripts/analysis/aggregate_m57_formal.py --finalize
```

## 24. Evidence files

- `docs/m57_*.md`
- `formal/harness/formal_m57_fullrtl_write_path_tb.sv`
- `scripts/run/run_m57_verilator_assert.sh`
- `results/tables/m57_pre_post_formal_matrix.csv`
- `results/formal/m57/pre_fix_counterexamples/`
- `results/figures/m57_*`

## 25. Recommended next milestone

M5.8: Yosys-slang/Verific elaboration for SymbiYosys on same harness; PDR/induction on M57-FP-04; complete deny-path liveness in harness.

## 26. Current Git HEAD

Run after commit: `git rev-parse HEAD`

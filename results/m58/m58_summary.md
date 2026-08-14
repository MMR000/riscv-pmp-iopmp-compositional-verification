# Milestone M5.8: PARTIAL

## 1. Starting commit

`fcf7495` (M5.7), tag `checkpoint-m57-fullrtl-validation`

## 2. Final commit

`56f9ffe`

## 3. Branch

`m58-fullrtl-formal-proof`

## 4. M5.7 preservation status

- M5.6 replay: **REPRODUCED_IN_RTL_SIMULATION**
- Verilator FIX-2 directed: **BOUNDED_PASS**
- Verilator FIX-0 harness: **COUNTEREXAMPLE** (M57-FP-04 assertion at 255000 ps)

## 5. Formal frontend used

**Yosys 0.68 integrated `read_slang`** (primary). Verific: **VERIFIC_NOT_AVAILABLE**. Plugin built at `tools/yosys-slang/build/slang.so` as backup.

## 6. Elaboration result

**SUCCESS** — full RTL harness elaborates. See `docs/m58_elaboration_notes.md`.

## 7. Property definition

M57-FP-04: `mem_write_event -> w_context_ok` where `w_context_ok = grant_allow && (grant_seq == txn_seq)`. See `docs/m58_formal_properties.md`.

## 8. FIX-0 result

SymbiYosys BMC depth 64: **EXPECTED_PRE_FIX_COUNTEREXAMPLE** (step 5). Trace: `results/formal/m58/counterexamples/M57-FP-04_FIX0/`.

## 9. FIX-2 BMC result

Depths 16–128: **COUNTEREXAMPLE** at step 5 under minimal assumptions. **Not BOUNDED_PASS** — classified **ASSUMPTION_GAP** vs Verilator **BOUNDED_EVIDENCE**.

## 10. FIX-2 induction result

`smtbmc --presat z3`: **COUNTEREXAMPLE** (same as BMC). Not attempted to full k-induction proof.

## 11. FIX-2 PDR result

ABC PDR (`mode prove`): **COUNTEREXAMPLE** in 2 steps. Witness replay blocked (**yices not installed**). **Not FORMAL_PROOF**.

## 12. Assumptions

M58-FA-01..06, M58-FA-TOOL documented in `docs/m58_formal_assumptions.md`.

## 13. Assumption sensitivity

`results/tables/m58_assumption_sensitivity.csv`

## 14. Cover/reachability

`results/formal/m58/m58_cover_results.csv` — auth/deny/master-W covers reachable in formal model.

## 15. Counterexamples

FIX-0 BMC/PDR traces preserved under `results/formal/m58/fix0/` and `counterexamples/M57-FP-04_FIX0/`.

## 16. Denied-write completion classification

**FORMAL_MODEL_LIMITATION** — see `docs/m58_denied_write_completion.md`.

## 17. Regression results

M5.7 Verilator proper: PASS. M5.6 replay: PASS. Full m1/m2 not re-run this session.

## 18. Toolchain limitations

- SVA unsupported in read_slang → Yosys assert encoding
- PDR witness needs yices
- Free-input BMC over-approximates environment vs directed Verilator

## 19. Scientific interpretation

- **Major progress:** first successful SymbiYosys BMC on real IOPMP write-path RTL closure using read_slang.
- FIX-0 formal CE confirms the known defect class is reachable in the formal model.
- FIX-2 is **not** formally proved; directed Verilator evidence remains **BOUNDED_EVIDENCE**.
- Unbounded proof requires stronger AXI/IOPMP environment assumptions and likely liveness/fairness constraints.

## 20. Candidate paper contribution after M5.8

- Full-RTL formal elaboration methodology for open-source IOPMP AXI abstractor using read_slang.
- Cross-validation: simulation CE + SymbiYosys CE on FIX-0; repair validated by directed assertion on FIX-2.
- Explicit assumption-gap characterization between free-input BMC and directed simulation.

## 21. Recommended M5.9

Strengthen formal environment (AXI protocol constraints, fairness), re-run BMC/PDR, install yices for witness replay, minimize FIX-0 BMC trace vs M5.6 CE.

## 22. Reproduction commands

```bash
git checkout m58-fullrtl-formal-proof
bash scripts/m58/prepare_formal_rtl.sh
M58_VARIANT=original M58_DEPTH=64 bash scripts/run/run_m58_formal.sh
M58_VARIANT=proper M58_DEPTH=64 bash scripts/run/run_m58_formal.sh
M58_VARIANT=proper M58_MODE=prove bash scripts/run/run_m58_formal.sh
make m57-verilator
```

## 23. Evidence files

- `docs/m58_*.md`
- `results/tables/m58_formal_matrix.csv`
- `results/formal/m58/elaboration/`
- `results/formal/m58/counterexamples/`
- `results/m58/m58_environment.txt`

## 24. Git commit

Pending: `m5.8: read_slang full-RTL formal BMC for M57-FP-04`

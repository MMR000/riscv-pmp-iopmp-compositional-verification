# Milestone M5.9: COMPLETE

## 1. Starting commit

`8e47a6a` (M5.8 summary), main M5.8 work `56f9ffe`

## 2. Final commit

`9f2a98b`

## 3. Branch

`m59-axi-environment-proof-closure`

## 4. M5.8 reproduction

FIX-0 ENV-0 BMC: **EXPECTED_PRE_FIX_COUNTEREXAMPLE** (step 10 primary). FIX-2 M5.8 CE preserved in `results/formal/m59/baseline/fix2_m58_bmc64/`.

## 5. FIX-2 original formal counterexample

Dominated by **Yosys anyinit** on DUT FIFOs/FSM and harness observers. Zero master AW/W stimulus in witness. `route_select_q=1`, `ini_w_hs=1`, `grant_allow=0` at step 5 (M5.8).

## 6. AXI legality classification

**PROTOCOL_ILLEGAL_COUNTEREXAMPLE** — not a legal master-presented AXI write sequence.

## 7. FIX-2 RTL replay

**NOT_REPRODUCIBLE_DUE_TO_UNCONTROLLABLE_INTERNAL_STATE** — see `results/simulation/m59/fix2_ce_replay/`.

## 8. FIX-0 formal/simulation alignment

**DIFFERENT_COUNTEREXAMPLE** at formal ENV-0 vs M5.6 directed CE; Verilator full-RTL reproduces simulation class.

## 9. Formal environment contract

ENV-4 with M59-FA-01..12. Documented in `docs/m59_axi_environment_contract.md`, `docs/m59_compositional_contract.md`.

## 10. Assumption ladder

`results/tables/m59_assumption_ladder.csv` — FIX-2 primary **BOUNDED_PASS** at ENV-4 depth 512.

## 11. Minimal assumption set

M59-FA-04 (derived reset), M59-FA-10/11 (master quiescence), M59-FA-07 (post-reset idle). See minimization CSV.

## 12. FIX-0 BMC result

ENV-0: primary **EXPECTED_PRE_FIX_COUNTEREXAMPLE**. ENV-4 final: primary not re-found ≤1024 (secondary assert only).

## 13. FIX-2 BMC result

ENV-0: **COUNTEREXAMPLE** (M5.8 class). ENV-4: primary **BOUNDED_PASS** to depth 512.

## 14. FIX-2 induction result

**INCONCLUSIVE** — not pursued to proven k-induction.

## 15. FIX-2 PDR result

ABC PDR **FAIL**; **TOOLCHAIN_LIMITATION** (yices missing, no witness trace).

## 16. PDR witness replay

**WITNESS_UNREPLAYABLE**

## 17. Reachability/cover results

`results/formal/m59/m59_cover_results.csv` — auth/deny/AW-before-W covers reachable under ENV-4.

## 18. Safety/liveness separation

Denied-write completion remains **HARNESS_LIVENESS_LIMITATION** (M5.7). M5.9 scoped to safety only.

## 19. Regression results

m55/m56/m57 pass. See `results/tables/m59_regression_matrix.csv`.

## 20. Final scientific classification

| Target | Classification |
|--------|----------------|
| M5.8 FIX-2 CE | **ASSUMPTION_GAP** + **HARNESS_ARTIFACT** (anyinit) |
| FIX-2 primary M57-FP-04 @ ENV-4 | **BOUNDED_EVIDENCE** |
| FIX-2 unbounded proof | **INCONCLUSIVE** / **TOOLCHAIN_LIMITATION** |
| Genuine FIX-2 RTL defect | **Not supported** |

## 21. Paper-relevant conclusion

- Formal FIX-2 CE from M5.8 is **not** a verified RTL safety bug; it is an **anyinit/environment artifact**.
- Justified AXI master quiescence + reset contract yields **BOUNDED_EVIDENCE** aligning with Verilator directed pass.
- Cross-validation methodology: simulation CE ground truth vs formal anyinit witnesses.

## 22. Remaining limitations

- No yices → no PDR witness replay
- FIX-0 primary bug not re-found under ENV-4 within BMC 1024 (reachability depth)
- Secondary denied-write assert still fails at step 10 (observer anyinit edge)

## 23. Recommended M5.10

Bounded model checking depth extension for FIX-0 under ENV-4; install yices; optional `nomeminit`/reset closure for demux FIFOs; unbounded PDR retry.

## 24. Reproduction commands

```bash
git checkout m59-axi-environment-proof-closure
make m59-bmc
make m59-prove
python3 scripts/m59/replay_fix2_formal_ce.py
make m57-verilator
```

## 25. Evidence files

- `docs/m59_*.md`
- `results/tables/m59_*.csv`
- `results/formal/m59/`
- `results/simulation/m59/fix2_ce_replay/`

## 26. Git commit

`m5.9: classify FIX-2 formal CE as anyinit artifact; ENV-4 bounded evidence`

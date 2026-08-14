# Milestone M5.10: COMPLETE

## 1. Starting commit

`0a44ac8` (M5.9), tag `checkpoint-m59-axi-environment` on `9f2a98b`

## 2. Final commit

`681b2bd`

## 3. Branch

`m510-compositional-guarantee-matrix`

## 4. M5.9 preservation

M5.9 artifacts copied to `results/m510/preserve/`. No M5.9 evidence overwritten.

## 5. Unified property matrix

`results/tables/m510_property_matrix.csv` — simulation + BMC + PDR for SP-01..14, SP-B01, M57-FP-04 FIX-0/2.

## 6. RST-A vs RST-B formal comparison

| Question | RST-A | RST-B |
|----------|-------|-------|
| DMA protected write before secure_ready? | **Reachable (CE step 1)** | **Unreachable (FORMAL_PROOF)** |
| Classification | RESET_ASSUMPTION_DEPENDENCY | FORMAL_PROOF |

See `docs/m510_reset_model_comparison.md`.

## 7. INCONCLUSIVE closure

See `docs/m510_inconclusive_closure.md`. SP-11 PREUNSAT → FORMAL_HARNESS_BUG. FIX-2 M5.8 CE → closed as anyinit artifact (M5.9).

## 8. Assumption sensitivity matrix

`results/tables/m510_assumption_sensitivity.csv` — M59-FA ladder + RST-A/B + FA-01.

## 9. Consolidated guarantee table

`results/tables/m510_guarantee_matrix.csv`

## 10. Yices / PDR witness replay

**Skipped** (TOOLCHAIN_LIMITATION). No impact on existing proof status per user directive.

## 11. Counterexamples preserved

| Property | Path | Classification |
|----------|------|----------------|
| SP-08 RST-A | `results/formal/counterexamples/SP-08/` | RESET_ASSUMPTION_DEPENDENCY |
| SP-02, SP-04, SP-10, SP-B01 | `results/formal/counterexamples/` | Various (expected/model) |
| M57-FP-04 FIX-0 | `results/formal/m59/m59_original_env0_bmc128/` | EXPECTED_PRE_FIX_COUNTEREXAMPLE |
| M57-FP-04 FIX-2 M5.8 | `results/formal/m58/m58_proper_bmc64/` | HARNESS_ARTIFACT |

## 12. Regression

m55-baseline PASS, m56-regression PASS, m57-verilator FIX-2 BOUNDED_PASS, RST formal reconfirmed.

## 13. Scientific statement evaluation

**Supported** within documented scope:

> "Compositional PMP–IOPMP isolation depends not only on local access-control correctness, but also on initialization, reset ordering, requester identity, and transaction-admission invariants."

Evidence:
- **Reset ordering:** RST-A CE vs RST-B proof (SP-08)
- **Initialization:** `secure_ready = pmp_enable && iopmp_enable && rule0_valid`
- **Requester identity:** SP-06 simulation PASS; SP-04 formal PROVED
- **Transaction admission:** SP-11 (INCONCLUSIVE harness), M57-FP-04 write-binding BOUNDED_EVIDENCE at ENV-4
- **Local access-control:** SP-02/04 PROVED under FA assumptions

**Not claimed:** universal vulnerability, Ibex/FPGA validity, unbounded full-RTL proof of M57-FP-04.

## 14. Reproduction

```bash
git checkout m510-compositional-guarantee-matrix
make m510-matrix          # aggregate tables only
make m510-formal          # RST + write-path formal refresh
make m510                 # full M5.10
```

## 15. Evidence files

- `results/tables/m510_*.csv`
- `docs/m510_*.md`
- `results/m510/m510_environment.txt`
- `results/m510/preserve/`

## 16. Git commit

`m5.10: compositional guarantee matrix and RST-A/B formal comparison`

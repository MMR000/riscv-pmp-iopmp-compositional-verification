# M5.7 paper case study update

## Layer separation (formalized)

1. **Policy (Layer 1):** IOPMP `env_allow` / matching — modeled explicitly
2. **Enforcement (Layer 2):** initiator AW/W handshakes vs authorization — M57-FP-01..04
3. **Effect (Layer 3):** abstract `mem_written` — M57-FP-03/15

## Supported claims

- M5.6 simulation: repair eliminates M5.5 stale-route sequence (18/18 regression, 500/500 random)
- M5.7: M5.6 abstract formal harness failure classified **HARNESS_ABSTRACTION**, not RTL regression
- M5.7: Real RTL closure (`rv_iopmp_data_abstractor_axi` + `axi_demux`) compiles under Verilator assertions; directed auth→deny stimulus **passes on proper repair**
- Original defect remains **simulation-reproduced** (`results/m56/before_fix/M56-BEFORE-CE.txt`, `make m55-baseline`)

## Not yet supported

- Unbounded SymbiYosys proof (Yosys SV frontend INCONCLUSIVE on vendor packages)
- Unconditional "PROVED" for M57-FP-04 across all legal AXI timings without bounded assumptions

## Wording template

"The repaired implementation satisfies initiator-side write-binding invariants under Verilator assertion checking and bounded simulation regressions, within assumptions M57-FA-01..09."

Do **not** claim full-chip or specification-level proof.

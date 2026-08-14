# M6 limitations register

## Scope limitations

1. **Abstract CPU master** — not Ibex or a complete RISC-V processor.
2. **Research IOPMP model** — simplified; not claimed fully standards-compliant.
3. **No FPGA validation.**
4. **No ASIC/silicon validation.**
5. **No complete SoC security claim.**

## Evidence limitations

6. **M57-FP-04 FIX-2:** BOUNDED_EVIDENCE only; PDR raw FAIL is not a validated genuine counterexample.
7. **M5.8 FIX-2 CE:** closed as HARNESS_ARTIFACT (anyinit) in M5.9.
8. **SP-11:** FORMAL_HARNESS_BUG (PREUNSAT).
9. **SP-06, SP-07, SP-09:** primarily simulation evidence in current matrix.
10. **SP-13 BMC on C0:** counterexample expected for fail-open config; C1 proved separately.

## Toolchain limitations

11. **Yices unavailable** — PDR witness replay blocked.
12. **read_slang** required for full-RTL formal; Yosys 0.68 read -sv insufficient.

## Interpretation limitations

13. **RST-A SP-08 CE:** RESET_ASSUMPTION_DEPENDENCY — not a vulnerability in a named product.
14. **Formal proofs** hold only under documented FA/M59 assumptions and modeled RTL.
15. **PPA:** not measured; outside present scope.

## Preservation

16. M5.9 evidence frozen under `results/m510/preserve/` — must not be modified.

# M5 specification status

The RISC-V IOPMP material used in M5 is the **RISC-V IOPMP development specification v0.8.2** (official reference model release tag `v0.8.2`, commit `6c5392f`).

This is **not** described as a ratified IOPMP standard. Treat all IOPMP specification statements in M5 as applying to the **official RISC-V IOPMP draft/reference model** unless independently verified otherwise.

## Implications for M5

- REF-IOPMP behavior is authoritative for **EV-1** (reference-model reproduction).
- Independent RTL may target a different draft revision; version gaps are documented separately in `docs/m5_rtl_spec_gap.csv`.
- M4-IOPMP remains a frozen research abstraction (`checkpoint-m4-done`).

# M5.5 draft5 semantics (upstream RTL)

## Spec source pinned by upstream

- Repository: https://github.com/zero-day-labs/riscv-iopmp
- Commit: `a029581351aaf8a71831916aa8877895364e6e98`
- Register package: `packages/rv_iopmp/rv_iopmp_reg_pkg.sv` (generated from draft5 regmap)
- README references IOPMP **v1.0.0-draft5**

## Sections consulted (RTL comments / register layout)

| Topic | RTL location | Normative certainty |
|-------|--------------|---------------------|
| SRCMD per master | regmap addr stride 32B | **Architectural** (register map) |
| MD enable bit (bit n+1) | harness + regmap | **Observed encoding** |
| Unmapped source / no MD | matching SETUP→ERROR err 5 | **Implementation** |
| sid > NUMBER_MASTERS | matching ERROR err 6 | **Implementation** (off-by-one for sid==N) |
| Read/write permissions | entry_cfg[2:0] & access_type | **Shared** in entry_analyzer |
| Error response on deny | axi_err_slv RESP_SLVERR | **Implementation** |

## Unauthorized access expectation (draft5-aligned)

When enabled and source has no MD mapping: transaction should **not** reach initiator.
**CROSS_REVISION_COMPARABLE** with REF deny semantics; **REVISION_SPECIFIC** on reset/default enable.

## W channel

Draft5 AXI mapping expects full AW/W handshaking after authorization. Presenting W before AW
routing is resolved is **not** documented as allowed — classified as implementation defect.

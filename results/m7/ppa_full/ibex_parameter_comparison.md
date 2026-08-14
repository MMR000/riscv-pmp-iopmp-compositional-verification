# M7 J0-J3 Ibex parameter comparison (machine-readable)

source: m7/ppa/rtl/m7_ppa_top.sv ibex_top instantiation
ibex_commit: c61e11c1e416b9ce2d996013b444c8e558d35b2b

## Explicitly passed to ibex_top (all variants)

| Parameter | J0 | J1 | J2 | J3 |
|-----------|----|----|----|----|
| PMPEnable | 0 | 1 | 1 | 1 |
| PMPNumRegions | 8 | 8 | 8 | 8 |
| PMPGranularity | 0 | 0 | 0 | 0 |
| RV32M | ibex_pkg::RV32MFast | same | same | same |

## ibex_top defaults (not overridden; identical for J0-J3)

| Parameter | Value |
|-----------|-------|
| RV32E | 0 |
| RV32B | RV32BNone |
| RV32ZC | RV32ZcaZcbZcmp (package default) |
| RegFile | RegFileFF |
| BranchTargetALU | 0 |
| WritebackStage | 0 |
| ICache | 0 |
| ICacheECC | 0 |
| BranchPredictor | 0 |
| DbgTriggerEn | 0 |
| SecureIbex | 0 |
| MemECC | SecureIbex (=0) |
| ICacheScramble | 0 |
| MHPMCounterNum | 0 |
| PMPRstMsecCfg (Smepmp) | rlb=0 mmwp=0 mml=0 (off) |

## Composition parameters (not Ibex)

| Parameter | J0 | J1 | J2 | J3 |
|-----------|----|----|----|----|
| INCLUDE_COMPOSITION | 0 | 0 | 1 | 1 |
| INCLUDE_DOMAIN_RESET | 0 | 0 | 0 | 1 |
| RST_B define | no | no | no | yes |

## Fairness

J1-J0 isolates PMPEnable only.
J2-J1 adds DMA+IOPMP+adapter+arbiter (RST-A).
J3-J2 adds domain reset + RST_B fail-closed defaults.
No unexpected Ibex parameter differences.

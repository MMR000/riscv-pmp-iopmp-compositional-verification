# M7 Ibex integration (Phase A)

## Repository pin

| Field | Value |
|-------|-------|
| URL | https://github.com/lowRISC/ibex |
| Commit | `c61e11c1e416b9ce2d996013b444c8e558d35b2b` |
| License | Apache-2.0 |
| Path | `third_party/ibex/` |

## M7 configuration (reproducible)

| Parameter | Value | Notes |
|-----------|-------|-------|
| PMPEnable | 1 | Architectural PMP in Ibex |
| PMPNumRegions | 8 | Journal modest config (not 16) |
| PMPGranularity | 0 | 4-byte granularity |
| RV32M | RV32MFast | |
| RV32E | 0 | |
| SecureIbex | 0 | No Smepmp/mseccfg in this config |
| RegFile | RegFileFF | |

Smepmp is **not** enabled. Tests use standard `pmpcfg`/`pmpaddr` CSRs only.

## Toolchain

- RISC-V embedded GCC: xPack 14.2.0 at `third_party/toolchain/xpack-riscv-none-elf-gcc-14.2.0-3/`
- Verilator: 5.050 (conda-forge)
- FuseSoC: 2.4.3

## Bare-metal tests

Location: `m7/sw/ibex_pmp/` (IBEX-PMP-01 .. IBEX-PMP-08)

Build: `make -C m7/sw/ibex_pmp GCC=.../riscv-none-elf-gcc`

Run (when simulator builds): `scripts/run/run_m7_realcore.sh`

## Composed CPU+DMA SoC

**Status: IN PROGRESS / BLOCKED**

Target: Real Ibex (internal PMP) + existing DMA/IOPMP/interconnect + protected SRAM.

Blocker: Ibex `ibex_simple_system` Verilator build fails with `UNOPTFLAT` treated as error on commit `c61e11c` with Verilator 5.050. See `results/m7/ibex/build.log`.

Workaround attempted: Makefile `-Wno-UNOPTFLAT` injection in `run_m7_realcore.sh`.

IBEX-COMP-* compositional tests require composed top (`m7/rtl/ibex_composed_soc.sv` — not yet integrated).

## Local patches

None applied to Ibex RTL at this milestone.

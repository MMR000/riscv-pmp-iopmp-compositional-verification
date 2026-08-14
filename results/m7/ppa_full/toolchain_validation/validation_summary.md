# ORFS toolchain validation — Phase D.1

## Date
2026-08-12

## Classification
Official GCD + SKY130HD Ibex gates: **PASS**

(The earlier **PPA_TOOLCHAIN_BLOCKER** in commit `b1605e2` was Docker-not-installed. That blocker is resolved.)

## Environment

| Tool | Status |
|------|--------|
| Docker | PASS 29.7.2, build a7dcaa6 |
| ORFS image | PASS `openroad/orfs@sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277` |
| Yosys (container) | PASS 0.68+post |
| Slang | PASS built-in `read_slang` |
| OpenROAD (container) | PASS 26Q3-1080-gab6fd26351 |
| ORFS commit (host pin) | `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c` |
| Host ORFS submodules | not initialized (not required for Docker) |
| LEC_CHECK | 0 (Kepler AVX-512 vs i9-14900KF) |

## Validation

### nangate45/gcd
**PASS** — finish/GDS. setup WNS +0.016 ns, TNS 0, DRC 0. See `gcd/summary.md`.

### sky130hd/ibex (official, unmodified)
**PASS** — finish/GDS. clock 10.0 ns, setup WNS +0.069 ns, TNS 0, DRC 0. See `orfs_ibex/summary.md`.

## Consequence
Official physical-design toolchain is validated. **Do not start J0–J3 in this D.1 step.** J0–J3 may resume in a later step.

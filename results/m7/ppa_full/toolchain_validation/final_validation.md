# Phase D.1 final validation gate

date: 2026-08-12

The Docker blocker recorded in commit `b1605e2` (`m7(phase-d1): record Docker install blocker and ORFS validation gate`) **has been resolved**. Docker 29.7.2 is installed; `openroad/orfs:latest` is present; official GCD and SKY130HD Ibex full flows completed in the ORFS container.

## Gate results

| Check | Result |
|-------|--------|
| Docker | **PASS** — Docker 29.7.2, build a7dcaa6 (`sg docker` required in this agent session; user `mmr` is in group `docker`) |
| ORFS Docker image | **PASS** — `openroad/orfs:latest` Id/digest `sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277` |
| Yosys in container | **PASS** — Yosys 0.68+post at `/OpenROAD-flow-scripts/tools/install/yosys/bin/yosys` |
| Slang support | **PASS** — built-in `read_slang` (Yosys ≥0.67). `"$YOSYS_EXE" -m slang` fails because `slang.so` is not a plugin; that probe is the wrong test for this image |
| OpenROAD in container | **PASS** — `26Q3-1080-gab6fd26351` at `/OpenROAD-flow-scripts/tools/install/OpenROAD/bin/openroad` |
| GCD full flow | **PASS** — `designs/nangate45/gcd/config.mk` through finish/GDS |
| official SKY130HD Ibex full flow | **PASS** — `designs/sky130hd/ibex/config.mk` through finish/GDS (RTL/config unmodified) |

## Host ORFS pin

```text
third_party/OpenROAD-flow-scripts
f9ec54a6de7b2bc69fd586015f6ebdab34eca69c
```

Submodules remain **not initialized** on the host (`OpenROAD` / `yosys` / `kepler-formal` show `-` prefix). The Docker image already contains installed Yosys, OpenROAD, Kepler, KLayout, and PDKs. Host submodule init/build was **not** required for this Docker workflow.

## LEC_CHECK=0 (host CPU)

Default image LEC uses `kepler-formal`, which contains AVX-512 (`%zmm`) instructions. This host is an Intel Core i9-14900KF with AVX-512 fused off. The first GCD run died at CTS:

```text
Error: cts.tcl, 81 child killed: illegal instruction
```

Official ORFS workaround: `make LEC_CHECK=0 ...` (skips Kepler LEC; does not modify design RTL/config). Physical stages still run to GDS. Both validation gates used this flag.

Cosmetic container messages (`xauth`, `groups: cannot find name for group ID 1000`, `I have no name!`) did not block the flows.

## Phase A tooling (optional, non-blocking)

`libelf-dev` and `srecord` are installed. `scripts/run/run_m7_phase_a.sh` rebuilt successfully.

```text
Phase A REPRODUCTION_TOOLING_LIMITATION: CLOSED
```

Frozen PMP matrix SHA unchanged: `a6176844f91613a15845c9eff24c71fd0ec240fef14dab7f57c3cdbb35e09660`.

## Classification

Official toolchain validation gates: **PASS**.

Project J0–J3 physical PPA was **not** started (D.1 stop). J0–J3 may resume only after this report.

## Evidence

- `results/m7/ppa_full/toolchain_validation/container_versions.txt`
- `results/m7/ppa_full/toolchain_validation/docker_image_inspect.txt`
- `results/m7/ppa_full/toolchain_validation/gcd/summary.md`
- `results/m7/ppa_full/toolchain_validation/orfs_ibex/summary.md`
- `results/m7/ppa_full/orfs_pin.txt`

# Reproducibility

Commands below exist in this repository’s `Makefile` or scripts. Do not assume a `make help` target.

The top-level `Makefile` prepends `$(HOME)/miniconda3/bin` to `PATH`. That is a local convenience. Reproduction does **not** require that exact path: put `python3`, Verilator, Yosys, and related tools on `PATH`. Historical logs may still mention `/home/mmr/` or `miniconda3`; those strings are archived host evidence, not required setup.

## Reproduction tiers

### Tier 0 — Inspect frozen evidence

Seconds. No EDA stack.

```bash
python3 scripts/artifact/check_artifact.py
sha256sum -c results/FROZEN_EVIDENCE_MANIFEST.sha256
```

Read `results/tables/` and `docs/EVIDENCE_MAP.md`.

### Tier 1 — Figures / CSV analysis

Python 3 only.

```bash
python3 scripts/figures/generate_journal_figures.py
```

### Tier 2 — RTL simulation

Verilator, FuseSoC, RISC-V GCC (xPack 14.2.0 family was used), pinned Ibex.

```bash
bash scripts/setup/fetch_dependencies.sh
bash scripts/run/run_m7_phase_a.sh
make m7-ibex-composed
make m7-reset
make m7-ibex-reset
make m7-ibex-reset-inflight
make m7-ibex-release-orders
make m7-performance
```

Place `riscv-none-elf-gcc` on `PATH` or under `third_party/toolchain/` as the `scripts/run/run_m7_*.sh` wrappers expect.

### Tier 3 — Formal experiments

Yosys, SymbiYosys, Z3 (or another configured solver).

```bash
make m510-matrix
make m510
```

Related earlier targets also exist: `make formal`, `make formal-full`, `make m3`, `make m35`, `make m56-formal`, `make m57`, `make m58`, `make m59`.

This does **not** formally prove full Ibex composition.

### Tier 4 — Physical design

Docker + OpenROAD Flow Scripts + SKY130HD. High runtime and storage. Not a 30-second operation.

```bash
bash scripts/setup/fetch_dependencies.sh
make m7-ppa-full
```

Use the validated image digest in `third_party/pins/orfs_docker.digest`. `LEC_CHECK=0` for all reported J0–J3 runs (Kepler-formal on the validated image required AVX-512 that the experimental host did not provide).

## Final IEEE Access formal / PPA entry points

Pinned solver for the cleanup rerun: `tools/z3/bin/z3` (Z3 4.13.4, binary SHA-256 `e0385660ab6f1314049376c6188e70ab91692cdca4680b7b1cb42cac258ea836`). Yosys `0.68+` `832843ad0-dirty`. SymbiYosys `--version` reports `unknown SBY version`; git `v0.68` / `b1a1e98c…`.

| Task | Config | Expected | Runtime |
|------|--------|----------|---------|
| SP-08 RST-B | `formal/sby/sp08_rstb_prove.sby` | PASS, depth 20, induction step 3 | GNU wall 0:28.24, RSS 322484 kB, 1 assert |
| ARB-1–ARB-10 v2 (one cone) | `prod_arbiter_v2_prove.sby` (copy under `results/ieee_access_final/formal/prod_arbiter_v2_prove/`) | PASS, depth 24, induction step 19 | GNU wall 1:46.54, RSS 581920 kB, 34 asserts |
| Any-address no-regrant | `noregrant_any_prove.sby` (copy under `results/ieee_access_final/formal/noregrant_any_prove/`) | PASS, depth 20, induction step 11 | GNU wall 0:49.05, RSS 515924 kB, 11 asserts |
| IF01-A final ledger | rebuild C.5 then IF01-A RST-B DELAY=8 | 1/1/1, grant 32, write 43, `0x600d00c1` | individual Verilator wall in some logs prints 0 s (not useful); campaign aggregate `NOT_RECORDED` |
| IF02-A corrected | same C.5 binary | suite PASS, `sb_fail=0`, TXN_ID 1 then 2 | `NOT_RECORDED` beyond log |
| IF03-C / IF03-D | same | `err=NOT_ISSUED` / `err=0` | `NOT_RECORDED` |
| J2 / J3 final_dd7fe6 | `FLOW_VARIANT=final_dd7fe6 CLOCK_PERIOD=20.0 bash scripts/ppa/run_orfs_m7_docker.sh J2\|J3` | area 277641 / 280331, DRC 0, GDS YES | 1710 s / 1415 s |

Logs: `results/ieee_access_final/`. Do not change properties merely to obtain PASS.

C.5 campaigns are **separate** (do not add counts):

1. IF/STALE directed — `results/tables/m7_inflight_reset_matrix.csv`
2. ORD-A..H × RST-A/B — `results/tables/m7_realcore_release_order_matrix.csv`
3. 200-seed RAND-ORD — 200 files `results/m7/realcore_reset_c5/tests/RAND-ORD_s*.log` **and** `results/tables/m7_realcore_release_order_random.csv` (this public snapshot has the CSV; the any-address source zip did not)

Finite campaign results are `SIMULATION_EVIDENCE`, not exhaustive proof.

## Environment snapshot

`results/environment.txt` records host tools at an earlier date (Verilator 5.050, Yosys 0.68+, Python 3.13.9, …). Absolute conda paths in that file are historical.

ORFS container versions: `results/m7/ppa_full/toolchain_validation/container_versions.txt`.

## Waveforms

Selected small M4 dumps are under `results/m4/waveforms/`. Larger dumps are omitted; see `docs/WAVEFORM_REPRODUCTION.md`.

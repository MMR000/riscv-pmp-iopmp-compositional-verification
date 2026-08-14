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

## Environment snapshot

`results/environment.txt` records host tools at an earlier date (Verilator 5.050, Yosys 0.68+, Python 3.13.9, …). Absolute conda paths in that file are historical.

ORFS container versions: `results/m7/ppa_full/toolchain_validation/container_versions.txt`.

## Waveforms

Selected small M4 dumps are under `results/m4/waveforms/`. Larger dumps are omitted; see `docs/WAVEFORM_REPRODUCTION.md`.

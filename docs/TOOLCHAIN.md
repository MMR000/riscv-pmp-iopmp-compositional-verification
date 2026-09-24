# Toolchain

Values below are taken from frozen experiment records (`results/environment.txt`, `results/m7/ppa_full/toolchain_validation/container_versions.txt`, `docs/m7_ibex_integration.md`, pin files). They are the **validated** experimental stack, not a claim that every reviewer host matches.

| Component | Recorded value | Source |
|-----------|----------------|--------|
| Ibex | `c61e11c1e416b9ce2d996013b444c8e558d35b2b` | `third_party/pins/ibex.commit` |
| OpenROAD Flow Scripts (host) | `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c` | `third_party/pins/orfs.commit` |
| ORFS Docker image | `sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277` | `third_party/pins/orfs_docker.digest`; `container_versions.txt` |
| Yosys (ORFS image) | `0.68+post` | `container_versions.txt` |
| OpenROAD (ORFS image) | `26Q3-1080-gab6fd26351` | `container_versions.txt` |
| Primary PPA platform | SKY130HD | `m7/ppa/orfs/sky130hd/`; fairness check |
| `LEC_CHECK` | `0` for all J0–J3 | Kepler-formal in the validated image required AVX-512 unavailable on the experimental host; identical omission for fairness |
| Verilator | 5.050 | `results/environment.txt` |
| FuseSoC | 2.4.3 | `docs/m7_ibex_integration.md` (host `fusesoc --version`) |
| RISC-V GCC | xPack 14.2.0 (`xpack-riscv-none-elf-gcc-14.2.0-3`) | `docs/m7_ibex_integration.md` |
| Host Yosys (simulation/formal conda) | `0.68+` | `results/environment.txt` |
| Z3 (pinned cleanup rerun) | 4.13.4 (`tools/z3/bin/z3`) | `results/ieee_access_final/TOOL_VERSIONS.txt`; binary SHA-256 `e0385660ab6f1314049376c6188e70ab91692cdca4680b7b1cb42cac258ea836` |
| Yosys (cleanup formal) | `0.68+` git `832843ad0-dirty` | `results/ieee_access_final/formal/TOOL_VERSIONS.txt` |
| SymbiYosys | `--version` = `unknown SBY version`; git tag `v0.68` / `b1a1e98cba941ec8433f8dc27f416cd7bb7f14be` | do not invent a cleaner version string |
| J2/J3 FLOW_VARIANT | `final_dd7fe6` | sky130hd, 20 ns, image `817b608c…` |

`LEC_CHECK=0` is a `TOOLCHAIN_LIMITATION` / `REPRODUCTION_TOOLING_LIMITATION`, applied uniformly. It is not a per-variant fairness break.

Do not download PDKs or compiler tarballs unless you intentionally run Tier 2–4 reproduction.

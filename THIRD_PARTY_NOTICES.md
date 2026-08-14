# Third-party notices

This artifact depends on external projects that are **fetched**, not vendored. Recorded pins are in `third_party/pins/` and `docs/TOOLCHAIN.md`.

| Component | Upstream | Recorded revision / version | License (upstream) |
|-----------|----------|-----------------------------|--------------------|
| lowRISC Ibex | https://github.com/lowRISC/ibex | `c61e11c1e416b9ce2d996013b444c8e558d35b2b` | Apache-2.0 (see upstream `LICENSE`) |
| OpenROAD Flow Scripts | https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts | `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c` | BSD-style (see upstream) |
| ORFS Docker image | `openroad/orfs` | `sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277` | image / tool licenses inside the container |
| RISC-V IOPMP official reference | https://github.com/riscv-non-isa/riscv-iopmp | `6c5392f2ee103255a0a53a53698d423002c401cc` (v0.8.2) | Apache-2.0 (reference model); spec CC-BY-4.0 |
| zero-day-labs RISC-V IOPMP | https://github.com/zero-day-labs/riscv-iopmp | `a029581351aaf8a71831916aa8877895364e6e98` | Apache-2.0 + SHL-2.1 (upstream) |
| Verilator | https://github.com/verilator/verilator | 5.050 | LGPL-3.0 |
| FuseSoC | https://github.com/olofk/fusesoc | 2.4.3 | BSD-2-Clause (upstream) |
| Yosys | https://github.com/YosysHQ/yosys | 0.68+ / 0.68+post (ORFS image) | ISC |
| OpenROAD | https://github.com/The-OpenROAD-Project/OpenROAD | `26Q3-1080-gab6fd26351` | BSD-3-Clause (upstream) |
| RISC-V GCC (xPack) | https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack | 14.2.0 | GPL and related toolchain licenses |

Do not copy full upstream license texts into this file. After `fetch_dependencies.sh`, read `LICENSE` / `COPYING` in each checkout.

SKY130HD PDK files are **not** stored here; they are consumed via the ORFS container/flow when running Tier 4.

# Third-party dependencies

This public artifact does **not** vendor full third-party source trees, toolchains, PDKs, or Docker filesystems.

Fetch pinned revisions with:

```bash
bash scripts/setup/fetch_dependencies.sh
```

Optional IOPMP reference/RTL checkouts (needed for M5–M5.9 reproduction, not for inspecting frozen M7 tables):

```bash
bash scripts/setup/fetch_dependencies.sh --with-iopmp
```

The script never updates a checkout to `latest`. It clones if absent and checks out the exact recorded commit.

## Pins

| Component | Record | Value |
|-----------|--------|-------|
| lowRISC Ibex | `third_party/pins/ibex.commit` | `c61e11c1e416b9ce2d996013b444c8e558d35b2b` |
| OpenROAD Flow Scripts (host) | `third_party/pins/orfs.commit` | `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c` |
| Validated ORFS Docker image | `third_party/pins/orfs_docker.digest` | `sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277` |
| zero-day-labs RISC-V IOPMP | `third_party/pins/zero-day-labs-riscv-iopmp.commit` | `a029581351aaf8a71831916aa8877895364e6e98` |
| RISC-V IOPMP official (v0.8.2) | `third_party/pins/riscv-iopmp-official.commit` | `6c5392f2ee103255a0a53a53698d423002c401cc` |

## Layout after fetch

```text
third_party/
  README.md
  pins/
  ibex/                          # created by fetch_dependencies.sh
  OpenROAD-flow-scripts/         # created by fetch_dependencies.sh
  zero-day-labs-riscv-iopmp/     # optional --with-iopmp
  riscv-iopmp-official/          # optional --with-iopmp
```

Place a RISC-V GCC (xPack 14.2.0 family was used) on `PATH`, or under `third_party/toolchain/` as expected by `scripts/run/run_m7_*.sh`. Do not commit that toolchain into Git.

PDKs and ORFS tool binaries come from the validated Docker image when running physical design. They are not stored in this repository.

See `docs/TOOLCHAIN.md` and `THIRD_PARTY_NOTICES.md`.

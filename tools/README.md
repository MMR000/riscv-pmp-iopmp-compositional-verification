# Formal toolchain (M3+)

## Required

- **Yosys** — conda or system package
- **SymbiYosys** — vendored under `tools/SymbiYosys/` (run via `tools/SymbiYosys/sbysrc/sby.py`)
- **Z3** — download and symlink:

```bash
# Example (adjust version/path as needed):
cd tools
wget -q https://github.com/Z3Prover/z3/releases/download/z3-4.13.4/z3-4.13.4-x64-glibc-2.35.zip
unzip -q z3-4.13.4-x64-glibc-2.35.zip
ln -sf z3-4.13.4-x64-glibc-2.35/bin z3
```

Verify: `yosys --version`, `python3 tools/SymbiYosys/sbysrc/sby.py --version`, `tools/z3/bin/z3 --version`

## Optional

- **Boolector** — not required for M3/M3.5; Z3 is the primary solver.

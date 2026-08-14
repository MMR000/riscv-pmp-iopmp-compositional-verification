# Formal verification (Milestone M3)

SymbiYosys + Yosys + Z3 formal flow for the research PMP/IOPMP model.

## Layout

```text
formal/harness/   — formal tops using production RTL
formal/sby/       — SymbiYosys task files
formal/properties/ — (reserved) property modules
```

## Toolchain

```bash
export PATH="$PWD/tools/z3/bin:$HOME/miniconda3/bin:$PATH"
yosys -V
python3 tools/SymbiYosys/sbysrc/sby.py --help
z3 --version
```

Boolector is not installed; all tasks use `smtbmc z3`.

## Run

```bash
make formal          # smoke (SP-02, SP-04 unit, SP-B01)
make formal-full     # full suite including integration, reset, covers
make m3              # M1 + M2 + formal-full
```

Results: `results/formal/m3_runs.csv`, `results/formal/m3_summary.md`

## Tasks

| Task | Properties |
|------|------------|
| sp02_pmp_unit | SP-02 |
| sp04_iopmp_unit | SP-04, SP-05, SP-06, SP-07, SP-09 |
| sp10_integration | SP-02, SP-04, SP-05, SP-10 |
| sp08_reset | SP-08 (RST-A fail-open) |
| spb01_model_b | SP-B01 strong revocation (expected CE on Model A) |
| m3_cover | reachability covers |

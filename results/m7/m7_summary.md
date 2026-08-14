# Milestone M7: PARTIAL

Journal validation infrastructure and partial evidence. Ibex composed SoC and journal-grade PPA remain blocked on toolchain/integration.

---

## 1. Starting HEAD

`b0d66661b938ab55075fee650be0bfa55ec5249a` (branch `m6-publication-freeze`)

## 2. Final HEAD

`b0d66661b938ab55075fee650be0bfa55ec5249a` (M7 artifacts uncommitted)

## 3. Branch

`m7-journal-validation`

## 4. M5.10/M6 regression status

**PASS** — `make m510-matrix` (exit 0), `make m510` (exit 0, ~42s). See `results/m7/reproduction/m510_regression.md`.

## 5. Ibex repository / commit / configuration

| Field | Value |
|-------|-------|
| URL | https://github.com/lowRISC/ibex |
| Commit | `c61e11c1e416b9ce2d996013b444c8e558d35b2b` |
| PMPEnable | 1 |
| PMPNumRegions | 8 |
| PMPGranularity | 0 |
| RV32M | RV32MFast |
| Smepmp | not enabled |

Doc: `docs/m7_ibex_integration.md`

## 6. Real PMP software tests

**BLOCKED** — ELFs not yet built/run. Blockers: (1) Ibex Verilator sim build (`UNOPTFLAT` + missing `libelf.h`), (2) bare-metal `-march` needs `_zicsr`. Tests authored at `m7/sw/ibex_pmp/`.

## 7. Real-core compositional CPU/DMA tests

**NOT RUN** — requires `ibex_composed_soc` integration (IBEX-COMP-01..08). Not started.

## 8. Reset-domain architecture

**DELIVERED** — `rtl/soc/m7_reset_top.v`, `docs/m7_reset_architecture.md`

## 9. RST-A/RST-B results

Simulation via `m7_reset_top` + cocotb (C0/C1, R1/R2/R10/R11, 32 randomized seeds/config):

- RST-A (C0): R1 unsafe reachable → `RESET_ASSUMPTION_DEPENDENCY` (see raw CSV after re-aggregate)
- RST-B (C1): R1 blocked → `EXPECTED_BY_MODEL`

Table: `results/tables/m7_reset_matrix.csv`

## 10. Measured reset/recovery latencies

Partial — `secure_ready_latency` cycles recorded for staggered-release sequences in reset matrix (e.g. 3–15 cycles in C1 seeds). Full R1–R16 suite not yet complete.

## 11. Multi-requester/outstanding results

**PARTIAL** — `results/tables/m7_multimaster_matrix.csv`:

- M7-MR-01,03,04: PASS (simulation, 1 requester)
- Outstanding depth 2/4/8: `UNSUPPORTED_BY_IMPLEMENTATION` (research IOPMP)

## 12. Common-target synthesis/PPA toolchain

**TOOLCHAIN_LIMITATION** — OpenROAD/Liberty/FPGA not available. Yosys synthesis-only cell counts.

`results/m7/ppa/toolchain.txt`, `results/tables/m7_ppa.csv`

## 13. PPA table

Generated (synthesis-only): `results/tables/m7_ppa.csv`, `m7_ppa_summary.csv`. J0–J4 use research PMP/IOPMP modules; **not** full Ibex SoC.

## 14. Performance table

`results/tables/m7_performance.csv` — inherits M4 cycle baselines where available.

## 15. Independent IOPMP original-vs-FIX-2 overhead

I0/I1 Yosys attempts in `results/m7/ppa/raw/` (read_slang may fail without full file list — check logs).

## 16. SP-06 formal status

**BOUNDED_EVIDENCE** — reproduction via `sp04_iopmp_prove.sby` (bundled harness). No new standalone proof.

## 17. SP-09 formal status

Unit BMC depth 32 historically; M7 reproduction in `results/m7/formal/sp06_sp09_unit/`.

## 18. M57-FP-04 final status

**BOUNDED_EVIDENCE** unchanged. M59 ENV-4 BMC raw FAIL (secondary assert step 10); not promoted to violation.

## 19. New implementation defects

None identified in M7 runs.

## 20. New harness artifacts

M7 reset cocotb initially hit ReadOnly-phase reset drive — **fixed** (not a scientific finding).

## 21. Genuine property counterexamples

None new. M5.10 RST-A CE preserved; not reinterpreted.

## 22. Toolchain limitations

- Ibex sim: Verilator `UNOPTFLAT` as error; `libelf-dev` missing
- PPA: no OpenROAD/Liberty/FPGA
- Yices: still unavailable (PDR witness replay)

## 23. Evidence files

- `results/tables/m7_reset_matrix.csv`
- `results/tables/m7_multimaster_matrix.csv`
- `results/tables/m7_ppa.csv`
- `results/tables/m7_performance.csv`
- `results/tables/m7_formal_matrix.csv`
- `results/tables/m7_final_guarantee_matrix.csv` (copy of m510)
- `results/tables/m7_realcore_security_matrix.csv`
- `docs/m7_ibex_integration.md`, `docs/m7_reset_architecture.md`, `docs/iopmp_spec_alignment.md`

## 24. Reproduction commands

```bash
make m510-matrix
make m510
make m7-reset
make m7-multimaster
make m7-ppa
make m7-formal
make m7-realcore   # blocked on Ibex sim build
make m7
```

## 25. Scientific interpretation (max 12 bullets)

- M5.10 compositional conclusions **unchanged** and reproduced.
- RST-A vs RST-B distinction preserved in M7 reset simulation (`RESET_ASSUMPTION_DEPENDENCY` vs `EXPECTED_BY_MODEL`).
- Multi-domain reset release confirms staggered ordering affects `secure_ready_latency` without new violation claims.
- Research IOPMP outstanding depth >1 is **unsupported** — not emulated.
- Requester-ID isolation (M7-MR-01) holds in simulation at depth 1.
- M57-FP-04 remains **BOUNDED_EVIDENCE**; raw BMC/PDR FAIL not promoted.
- Ibex architectural PMP validation **pending** sim/toolchain closure.
- Composed Ibex+DMA journal claims **not yet supported** by new evidence.
- PPA numbers are **synthesis-only** cell counts, not journal-grade timing/area.
- No new genuine RTL counterexamples.
- No product vulnerability claims added.
- Spec alignment documented; research model **not** standards-compliant.

## 26. Journal limitations closed

- Multi-domain reset sequencing (partial)
- Multi-requester simulation at depth 1 (partial)
- IOPMP spec alignment doc updated
- Formal reproduction attempt logged

## 27. Limitations remain

- Real Ibex PMP execution unverified
- Ibex+DMA composed SoC unintegrated
- Journal PPA (placement, Fmax, power)
- Outstanding depth >1 on research IOPMP
- SP-06 standalone formal proof
- M57-FP-04 unbounded proof
- FPGA/ASIC validation

## 28. Claims strengthened for paper (when Ibex completes)

- Architectural PMP on real Ibex (pending IBEX-PMP-*)
- Compositional CPU+DMA with real core (pending IBEX-COMP-*)
- Measured reset latencies under independent domains (partial evidence exists)
- Synthesis overhead on common target (pending real SoC top)

## 29. Current Git HEAD

`b0d66661b938ab55075fee650be0bfa55ec5249a`

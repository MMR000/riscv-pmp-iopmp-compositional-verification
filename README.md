# Compositional Verification of PMP–IOPMP Isolation in RISC-V SoCs

![RISC-V](https://img.shields.io/badge/ISA-RISC--V-blue)
![Ibex](https://img.shields.io/badge/core-lowRISC%20Ibex-green)
![Evidence](https://img.shields.io/badge/evidence-formal%20%2B%20simulation%20%2B%20PPA-lightgrey)

Public research artifact for:

**Compositional Verification of PMP–IOPMP Isolation in RISC-V SoCs: Reset Ordering, Initialization, and Transaction Invariants**

This repository contains the RTL, formal harnesses, real-Ibex software, reset-ordering experiments, analysis scripts, frozen result tables, and figure-generation scripts used in the work. It is a curated publication snapshot, not a dump of the internal experimental Git history.

## Paper

See [docs/PAPER_ARTIFACT_TEXT.md](docs/PAPER_ARTIFACT_TEXT.md) for ready-to-paste artifact-availability wording.

Manuscript sources (LaTeX) live under [paper/](paper/). IEEE class files are **not** redistributed; obtain `IEEEtran` from IEEE / TeX Live.

## Research Question

Does local PMP/IOPMP access-control correctness compose into an end-to-end protected-memory isolation guarantee under reset, initialization, requester identity, and transaction-admission semantics?

**Conclusion.** Correct PMP and IOPMP enforcement is necessary but insufficient for end-to-end isolation unless initialization, reset ordering, requester identity, and transaction-admission semantics are also constrained.

## Architecture

```text
                    Real Ibex
                       |
                Architectural PMP
                       |
                       +-------------------+
                                           |
DMA Master --> IOPMP ----------------------+--> Shared fabric
                                           |
                                      Protected SRAM
```

Ibex PMP filters **CPU** data/instruction accesses. DMA does **not** traverse Ibex PMP. A research IOPMP sits on the DMA path. Reset / security-readiness is a separate control domain (RST-A fail-open vs RST-B fail-closed), not an extra PMP inserted after Ibex.

Evaluated physical-design variants:

| Variant | Meaning |
|---------|---------|
| **J0** | Real Ibex baseline, architectural PMP disabled |
| **J1** | J0 + architectural Ibex PMP |
| **J2** | J1 + DMA + research IOPMP + composed fabric (RST-A) |
| **J3** | J2 + fail-closed reset / security-readiness logic (RST-B) |
| **J4** | `NOT_APPLICABLE_TO_REALCORE_TOP` |

## Main Findings

Numbers below are read from frozen tables under [results/tables/](results/tables/). Evidence classes are preserved: do not promote simulation or bounded results to unbounded proof.

| Result | Evidence | Class |
|--------|----------|-------|
| Real Ibex PMP directed tests 8/8 PASS | [m7_ibex_pmp_matrix.csv](results/tables/m7_ibex_pmp_matrix.csv) | `SIMULATION_EVIDENCE` |
| Real Ibex + DMA/IOPMP composition 8/8 PASS | [m7_ibex_composed_matrix.csv](results/tables/m7_ibex_composed_matrix.csv) | `SIMULATION_EVIDENCE` |
| Composition scenario-sampling 100/100 PASS | [m7_ibex_composed_random.csv](results/tables/m7_ibex_composed_random.csv) | `SIMULATION_EVIDENCE` |
| Real-core reset random campaign 100/100 PASS vs modeled expectations | [m7_realcore_reset_random.csv](results/tables/m7_realcore_reset_random.csv) | mixed; RST-A is `RESET_ASSUMPTION_DEPENDENCY` |
| Independent deterministic release orders 16/16 matched expected reset-model behavior | [m7_realcore_release_order_matrix.csv](results/tables/m7_realcore_release_order_matrix.csv) | RST-A `RESET_ASSUMPTION_DEPENDENCY`; RST-B `SIMULATION_EVIDENCE` |
| Random release-order campaign 200/200 matched expected behavior | [m7_realcore_release_order_random.csv](results/tables/m7_realcore_release_order_random.csv) | same split |
| RST-A: early unauthorized DMA reachability under fail-open assumptions | [m7_realcore_reset_matrix.csv](results/tables/m7_realcore_reset_matrix.csv) | `RESET_ASSUMPTION_DEPENDENCY` — not a vulnerability |
| RST-B: fail-closed behavior in real-core simulation | same + release-order tables | `SIMULATION_EVIDENCE` |
| Abstract RST-B: formal evidence under stated assumptions | [m510_guarantee_matrix.csv](results/tables/m510_guarantee_matrix.csv) | `FORMAL_PROOF` (abstract model; **not** full-Ibex formal proof) |

### Physical design (main comparison)

Post-route **open-source RTL-to-GDS implementation estimate** on **SKY130HD**, common **20 ns** clock, identical memory policy, identical ORFS image, `LEC_CHECK=0` for all variants. This is **not** silicon measurement or ASIC validation.

From [m7_journal_ppa_main.csv](results/tables/m7_journal_ppa_main.csv) and [m7_full_ibex_ppa_20ns_overhead.csv](results/tables/m7_full_ibex_ppa_20ns_overhead.csv):

| Variant | Post-route stdcell area | Overhead |
|---------|-------------------------|----------|
| J0 | 157366 | baseline |
| J1 | 241200 | J1 vs J0 **+53.27%** |
| J2 | 279752 | J2 vs J1 **+15.98%** |
| J3 | 280749 | J3 vs J2 **+0.36%**; J3 vs J0 **+78.41%** |

J3 vs J2 is **near area-neutral at post-route in this flow**. Mapping/synthesis cell counts can move in the opposite direction (J3 vs J2 synth cells −1.62%); that fluctuation is not a claim that fail-closed reset reduces hardware cost.

Demonstrated post-route Fmax (shortest full post-route PASS), from [m7_journal_timing_summary.csv](results/tables/m7_journal_timing_summary.csv):

| Variant | Demonstrated Fmax |
|---------|-------------------|
| J0 | 105.26 MHz |
| J1 | 60.61 MHz |
| J2 | 78.43 MHz |
| J3 | 76.92 MHz |

Keep three PPA evidence types separate: (1) 20 ns common-period area, (2) 10 ns high-frequency **stress point**, (3) per-design demonstrated Fmax. J1 Fmax cause: `CAUSE_NOT_DEFINITIVELY_ESTABLISHED` — near-limit paths did not explicitly identify PMP ([docs/m7_j1_timing_anomaly_audit.md](docs/m7_j1_timing_anomaly_audit.md)).

## Performance

Distinct endpoints from [m7_journal_performance_summary.csv](results/tables/m7_journal_performance_summary.csv). Do not collapse them into one number.

**CPU (Phase A `mcycle`):**

- authorized protected load: 5 cycles
- authorized protected store: 5 cycles
- U-mode load fault: 28 cycles, `mcause=5`
- U-mode store fault: 30 cycles, `mcause=7`

**DMA landmarks:**

- admission → first commit: 5 cycles
- admission → completion: 7 cycles
- admission → last commit strobe: 9 cycles
- deny → response: same cycle / 0

**Measured sequential DMA** (single-outstanding research path), [m7_dma_throughput.csv](results/tables/m7_dma_throughput.csv):

| N | cycles/transfer | classification |
|---|-----------------|----------------|
| 16 | 14.75 | `MEASURED` |
| 64 | 14.9375 | `MEASURED` |
| 256 | 14.9844 | `MEASURED` |

## Evidence Levels

Use only these classes where relevant:

`FORMAL_PROOF` · `BOUNDED_EVIDENCE` · `SIMULATION_EVIDENCE` · `RESET_ASSUMPTION_DEPENDENCY` · `EXPECTED_BY_MODEL` · `RTL_IMPLEMENTATION_DEFECT` · `FORMAL_HARNESS_BUG` · `HARNESS_ARTIFACT` · `TOOLCHAIN_LIMITATION` · `REPRODUCTION_TOOLING_LIMITATION` · `UNSUPPORTED_BY_IMPLEMENTATION` · `INCONCLUSIVE`

See [docs/EVIDENCE_MAP.md](docs/EVIDENCE_MAP.md) and [results/tables/m7_reset_evidence_levels.csv](results/tables/m7_reset_evidence_levels.csv).

## Repository Structure

See [docs/REPOSITORY_STRUCTURE.md](docs/REPOSITORY_STRUCTURE.md). Working paths are preserved (`m7/`, `scripts/`, `results/`, `docs/`, `formal/`, `rtl/`).

## Quick Start

```bash
git clone \
  https://github.com/MMR000/riscv-pmp-iopmp-compositional-verification.git

cd riscv-pmp-iopmp-compositional-verification

python3 scripts/artifact/check_artifact.py
```

Then fetch pinned Ibex / ORFS sources (no PDK, no compiler tarball):

```bash
bash scripts/setup/fetch_dependencies.sh
```

Inspect frozen tables immediately (Tier 0). Heavy simulation, formal, and physical-design jobs are documented in [docs/REPRODUCIBILITY.md](docs/REPRODUCIBILITY.md).

## Reproducing Formal Results

Abstract-model / M5.10 matrix (requires Yosys / SymbiYosys / solver; **Tier 3**):

```bash
make m510-matrix
make m510
```

This is **not** a full-Ibex formal proof.

## Reproducing Real-Ibex PMP Tests

**Tier 2.** Requires Verilator, FuseSoC, pinned Ibex, and RISC-V GCC.

```bash
bash scripts/run/run_m7_phase_a.sh
```

## Reproducing Ibex + DMA Composition

```bash
make m7-ibex-composed
```

## Reproducing Reset Experiments

```bash
make m7-reset
make m7-ibex-reset
```

Phase C.5 in-flight and independent release orders:

```bash
make m7-ibex-reset-inflight
make m7-ibex-release-orders
```

## Reproducing Figures

**Tier 1.** Python only; reads frozen CSVs:

```bash
python3 scripts/figures/generate_journal_figures.py
```

See [docs/FIGURES.md](docs/FIGURES.md).

## Physical-Design Evaluation

**Tier 4 — high runtime and storage.** Docker + ORFS + SKY130HD. This is not a 30-second target.

```bash
make m7-ppa-full
```

Primary reported comparison is common 20 ns SKY130HD post-route area. Methodology: [docs/m7_full_ibex_ppa_methodology.md](docs/m7_full_ibex_ppa_methodology.md).

## Frozen Results

Experimental freeze:

- commit `07ee8931f8e7e75d48168914fffddb31a5e0a091`
- internal tag `checkpoint-m7-phase-d3-ppa-final`

Verify:

```bash
sha256sum -c results/FROZEN_EVIDENCE_MANIFEST.sha256
```

Details: [docs/FROZEN_EVIDENCE.md](docs/FROZEN_EVIDENCE.md), [PROVENANCE.md](PROVENANCE.md).

## External Dependencies

Pinned in [third_party/README.md](third_party/README.md) and [docs/TOOLCHAIN.md](docs/TOOLCHAIN.md):

- Ibex `c61e11c1e416b9ce2d996013b444c8e558d35b2b`
- ORFS `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c`
- ORFS image `sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277`

## Limitations

- Real-core composition uses a research single-outstanding DMA path.
- IOPMP configuration in real-core experiments is trusted harness-side configuration, not firmware MMIO.
- Full Ibex composition is not formally proven.
- Smepmp is not evaluated in the real-core experiments.
- No FPGA or silicon validation.
- Power is omitted.
- LEC was disabled in ORFS because the validated Kepler-formal binary required unavailable AVX-512 support on the host.
- I0/I1 FIX-2 standalone PPA was not run.
- IF01-A remains `INCONCLUSIVE` because REQUESTED→ADMITTED is a zero-width synchronous window in the evaluated implementation.

## Artifact Availability

https://github.com/MMR000/riscv-pmp-iopmp-compositional-verification

Public snapshot tag: see [docs/PAPER_ARTIFACT_TEXT.md](docs/PAPER_ARTIFACT_TEXT.md).

## Citation

See [CITATION.cff](CITATION.cff). Paper authors are not recorded in the manuscript source (placeholders only); cite the accompanying paper when published.

## License

This public snapshot currently has **no OSI project license**. See [docs/LICENSE_STATUS.md](docs/LICENSE_STATUS.md) and [LICENSES.md](LICENSES.md). Third-party notices: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

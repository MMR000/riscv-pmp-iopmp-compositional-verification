# Provenance

This GitHub repository is a **curated public artifact snapshot** of an internal experimental research tree. It is not a mirror of every internal branch, debug commit, or generated build.

## Relationship to the internal repository

| Item | Value |
|------|-------|
| Internal working tree (not public) | local research checkout used to produce this snapshot |
| Internal D.3 scientific freeze (historical) | `07ee8931f8e7e75d48168914fffddb31a5e0a091` / `checkpoint-m7-phase-d3-ppa-final` |
| Authoritative RC package | `IEEE_Access_Experimental_Evidence_Release_Candidate.zip` `67d82af4705cd9f8f19564f6c22ce60cd6e8647bfd561c8f40184d50e240f486` |
| Authoritative cleanup package | `IEEE_Access_Final_Evidence_Cleanup.zip` `7a91a075719e73eb4cad35450c737fa594f7b1b1135936015994d4d60ce31d91` |
| Public default branch | `main` |
| Current public freeze tag | `access-2026-41377-experimental-freeze` |
| Earlier public snapshot | `artifact-v1.0` at `5c8e2448c2d02835ce8047e428ee70a43278f881` (preserved) |

The D.3 freeze commit is **not rewritten**. This synchronization updates the public snapshot to the final verified engineering evidence. Cleanup values supersede conflicting earlier packages.

Internal experimental branches and `checkpoint-*` tags remain in the private research history and are **not** pushed by default.

## Milestone identifiers (internal Git, peeled to commit)

These SHAs were read from the internal repository with `git rev-parse <tag>^{commit}`. They are recorded for traceability; they are not public tags on this GitHub repository.

| Internal tag | Commit |
|--------------|--------|
| `checkpoint-m510-complete` | `681b2bd941b980460f03a62aee3d129b262babc5` |
| `checkpoint-m7-phase-a-ibex-pmp` | `574d99c39aed0381f3ed131e882c626aec472922` |
| `checkpoint-m7-phase-b-realcore-composition` | `eba4cae1c4d440972f03358ce27f62369c4dc6ae` |
| `checkpoint-m7-phase-c-realcore-reset` | `586fdd5781890d2b24417227de2428f271260a45` |
| `checkpoint-m7-phase-c5-reset-closure` | `15b75d285ecb01997f08de2f03076843367886dd` |
| `checkpoint-m7-phase-d-partial` | `8a4a085c782f92d158d082c80f9b2cc39304129b` |
| `checkpoint-m7-phase-d-toolchain-ready` | `0a86d81482498e1eae40a0807a19659f4516c342` |
| `checkpoint-m7-phase-d2-ppa-partial` | `7500156fbf076766a283a280465046e8b9ff02b9` |
| `checkpoint-m7-phase-d3-ppa-final` | `07ee8931f8e7e75d48168914fffddb31a5e0a091` |

Additional earlier internal tags exist (`checkpoint-m3-partial`, `checkpoint-m35-done`, `checkpoint-m4-done`, `checkpoint-m4-partial`, `checkpoint-m5-ev2`, `checkpoint-m5a-ev1`, `checkpoint-m55-write-defect`, `checkpoint-m56-write-path-repair`, `checkpoint-m57-fullrtl-validation`, `checkpoint-m58-fullrtl-formal`, `checkpoint-m59-axi-environment`). They were not invented; they were listed from `git tag --list`.

## What this snapshot contains

Research-created RTL (final production IOPMP `dd7fe6…`, arbiter `20477634…`), formal harnesses, real-Ibex software, scripts, compact frozen tables/metrics, selected small waveforms, documentation, figure sources, and the IEEE Access final evidence tree under `results/ieee_access_final/`.

## What this snapshot omits

- Full internal Git history and temporary debug commits
- Third-party source checkouts (Ibex, ORFS, IOPMP trees) — fetch via `scripts/setup/fetch_dependencies.sh`
- Toolchains, PDKs, Docker filesystems, conda/venv trees
- Verilator `sim-verilator/` and `obj_dir/` rebuilds
- Raw GDS / routed databases
- Formal solver model dumps (`*.smt2`, `*.il`)

See `docs/publication/repository_size_audit.md`.

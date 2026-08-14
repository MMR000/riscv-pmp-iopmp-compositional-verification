# GitHub Artifact Publication: COMPLETE

## 1. Local source commit

Internal branch `m7-journal-validation` at scientific freeze:

`07ee8931f8e7e75d48168914fffddb31a5e0a091`

Working tree was dirty with solver/log churn; those dumps were **not** published. Internal history was **not** rewritten.

## 2. Experimental freeze commit/tag

- Commit: `07ee8931f8e7e75d48168914fffddb31a5e0a091`
- Tag: `checkpoint-m7-phase-d3-ppa-final`

## 3. Public repository

https://github.com/MMR000/riscv-pmp-iopmp-compositional-verification

Default branch: `main`

Remote was not empty: GitHub “Initial commit” `4f653ce` (1-line README). That commit was **merged** with `-X ours` (no force-push). Research files were not overwritten.

## 4. Public main commit

`5c8e2448c2d02835ce8047e428ee70a43278f881`

## 5. Public artifact tag

`artifact-v1.0` → `5c8e2448c2d02835ce8047e428ee70a43278f881`

https://github.com/MMR000/riscv-pmp-iopmp-compositional-verification/tree/artifact-v1.0

## 6. Authentication status

`gh auth status`: logged in as `MMR000` (HTTPS, `repo`/`workflow` scopes). Push succeeded.

## 7. Secret audit

**PASS** — `docs/publication/secret_audit.md`

## 8. Large-file audit

No tracked file >50 MB (largest ~481 KB PPA log). No file near 95 MB. See `docs/publication/repository_size_audit.md`.

## 9. Third-party exclusions

Not committed: Ibex checkout, ORFS tree, xPack GCC, PDKs, Docker filesystem, `obj_dir/`, `sim-verilator/`, IEEEtran.cls, formal `model/`/`engine_0/` dumps. Pins + `scripts/setup/fetch_dependencies.sh` instead.

## 10. Public repository size

Fresh clone working tree: **36 MB**. Tracked files: **2885**. GitHub `size` API may lag at 0 KB immediately after the first push.

## 11. Key source directories published

`rtl/`, `m7/` (RTL, `sw/`, PPA configs, FuseSoC), `formal/` (harness/properties/sby/tasks), `tb/`, `scripts/`, `docs/`, `paper/` (TeX, no IEEE class), `m5/`/`m55/`/`m56/` adapters (no `obj_dir`), `patches/`.

## 12. Result tables published

All `results/tables/*.csv` including M5.10, Phase A–D, journal PPA/timing/performance matrices. SHA-256 in `results/FROZEN_EVIDENCE_MANIFEST.sha256`.

## 13. Formal evidence published

`.sby` tasks, harnesses, compact logs/status, M5.10 CSVs. Solver SMT2/IL/engine traces omitted.

## 14. Real-Ibex evidence published

`m7/sw/`, Phase A logs, `m7_ibex_pmp_matrix.csv`, composed matrices (8/8 and 100/100).

## 15. Reset evidence published

Directed/random/C.5 tables and compact logs. RST-A classified `RESET_ASSUMPTION_DEPENDENCY`. IF01-A `INCONCLUSIVE`.

## 16. PPA evidence published

Common 20 ns CSVs, overhead, Fmax sweep, timing summary, compact `metrics*.json`, fairness markdown, `container_versions.txt`. No GDS/ODB. Main comparison is 20 ns SKY130HD, not mixed-clock D.2.

## 17. Figure scripts published

`scripts/figures/generate_journal_figures.py` plus frozen CSVs and PDF/SVG under `results/figures/`. PNG rasters omitted.

## 18. README status

Root `README.md` written for an external reviewer (question, architecture, findings from CSVs, tiers, limitations).

## 19. CITATION.cff status

Present. No invented coauthors (manuscript still has placeholders). No invented DOI/volume.

## 20. License status

No OSI project license chosen. `docs/LICENSE_STATUS.md` + existing `LICENSES.md` (research use). Third-party notices recorded.

## 21. Frozen SHA256 manifest status

`sha256sum -c results/FROZEN_EVIDENCE_MANIFEST.sha256` **PASS** on the fresh clone.

## 22. Fresh-clone artifact check

```text
/tmp/riscv-pmp-iopmp-artifact-check
HEAD 5c8e2448c2d02835ce8047e428ee70a43278f881
tag  artifact-v1.0
python3 scripts/artifact/check_artifact.py  → ARTIFACT CHECK PASS
README relative links resolve
```

## 23. GitHub URL

https://github.com/MMR000/riscv-pmp-iopmp-compositional-verification

## 24. Stable artifact URL/tag

https://github.com/MMR000/riscv-pmp-iopmp-compositional-verification/tree/artifact-v1.0

## 25. Recommended exact paper repository statement

Artifact Availability—The RTL, formal harnesses, real-Ibex test software, reset-ordering experiments, analysis scripts, frozen result tables, and figure-generation scripts used in this work are publicly available at https://github.com/MMR000/riscv-pmp-iopmp-compositional-verification. The repository records the exact Ibex and OpenROAD Flow Scripts revisions, toolchain versions, and container digest used for the reported experiments. The frozen public snapshot is tagged `artifact-v1.0`.

## 26. Any omitted artifacts and why

| Omitted | Why |
|---------|-----|
| Internal Git history / `checkpoint-*` tags | Curated snapshot; provenance recorded in `PROVENANCE.md` |
| Ibex / ORFS / IOPMP full checkouts | Fetch pins; size and third-party policy |
| xPack GCC, PDK, Docker image filesystem | Multi-GB generated/tool content |
| Verilator `sim-verilator/`, `obj_dir/`, `*.gch` | Rebuildable binaries |
| GDS/ODB/SPEF, large GRT JSON, webp | Physical-design databases |
| Formal SMT2/IL/engine traces | Regenerable solver dumps |
| `paper/vendor/IEEEtran.cls` | IEEE redistribution not assumed |
| 600 dpi PNG figures | Vector PDF/SVG kept |
| Root scratch logs / compiled `*_sim` binaries | Not archival tables |

```text
PUBLIC ARTIFACT READY FOR PAPER CITATION
```

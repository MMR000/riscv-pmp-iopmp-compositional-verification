# Milestone M6: COMPLETE

Publication freeze and LaTeX paper skeleton delivered on branch `m6-publication-freeze`.

---

## 1. Starting commit

- Expected M5.10 checkpoint: `681b2bd` (tag `checkpoint-m510-complete`)
- Actual HEAD at M6 start: `b0d66661b938ab55075fee650be0bfa55ec5249a` (+1 docs commit after M5.10)
- Recorded in: `results/m6/m6_starting_state.txt`

## 2. Final commit

- `b0d66661b938ab55075fee650be0bfa55ec5249a` (M6 artifacts uncommitted at report time; branch tip unchanged from start)

## 3. Branch

- `m6-publication-freeze` (created from `m510-compositional-guarantee-matrix`)

## 4. M5.10 reproduction status

| Command | Exit | Runtime | Log |
|---------|------|---------|-----|
| `make m510-matrix` | 0 | ~5s | `results/m6/reproduction/m510_matrix.log` |
| `make m510` | 0 | ~45s | `results/m6/reproduction/m510_full.log` |

**Discrepancies:** None. Matrices regenerate successfully.

Details: `results/m6/reproduction/m510_reproduction.md`

## 5. Evidence freeze status

- M5.10 authoritative sources unchanged in interpretation; preserved M5.9 under `results/m510/preserve/` not modified
- M6 adds packaging only: claims register, limitations, paper skeleton, artifact generator
- Reproduction refreshed formal/sim logs under `results/` (expected side effect of `make m510`)

## 6. Generated claim matrix

- `results/m6/claims_evidence.csv`
- `results/m6/claims_evidence.md`
- LaTeX: `paper/tables/claims_evidence.tex`
- Claims CL-01 through CL-06 with evidence paths and reproduction commands

## 7. Generated paper tables

Auto-generated from `results/tables/m510_*.csv`:

- `paper/tables/property_summary.tex`
- `paper/tables/reset_comparison.tex`
- `paper/tables/assumption_sensitivity.tex`
- `paper/tables/formal_results.tex`
- `paper/tables/claims_evidence.tex`

## 8. Generated figures

- `paper/figures/architecture.tex` (TikZ)
- `paper/figures/reset_ordering.tex` (TikZ)
- `paper/figures/verification_workflow.tex` (TikZ)

## 9. LaTeX toolchain

- Engine: `pdflatex` (pdfTeX 3.141592653-2.6-1.40.25, TeX Live 2023/Debian)
- `latexmk`: not installed (Makefile falls back to pdflatex + bibtex)
- IEEEtran: vendored at `paper/vendor/IEEEtran.cls` (system package absent)
- Build log: `results/m6/paper_build.log`

## 10. Paper compile status

**SUCCESS** — clean build after macro-name and TikZ fixes (no LaTeX errors on final pass).

## 11. PDF path

`paper/build/main.pdf` (~116 KiB, 4 pages)

## 12. CHATGPT_HANDOFF.md path

`paper/CHATGPT_HANDOFF.md`

## 13. Bibliography status

- `paper/references.bib`: minimal verified entries (RISC-V privileged manual stub, SymbiYosys URL)
- TODO markers for literature; no fabricated DOIs or author lists
- Related-work candidates: `results/m6/nearest_work_candidates.csv`

## 14. Unresolved scientific issues

- M57-FP-04 FIX-2: **BOUNDED_EVIDENCE** only; PDR raw FAIL; no unbounded proof
- SP-11: **FORMAL_HARNESS_BUG** (PREUNSAT)
- SP-06 / SP-09: simulation evidence; limited standalone formal rows in m510 matrix
- M5.8 FIX-2 CE closed as **HARNESS_ARTIFACT** (M5.9); not an RTL defect claim

## 15. Unresolved tooling issues

- Yices not installed → PDR witness replay **TOOLCHAIN_LIMITATION**
- `latexmk` not installed (pdflatex fallback works)

## 16. Files changed (M6 deliverables)

**New:**

- `paper/` — full manuscript skeleton (main.tex, sections, tables, figures, appendix, generated/)
- `scripts/analysis/generate_paper_artifacts.py`
- `results/m6/` — starting state, reproduction logs, claims, limitations, nearest-work candidates
- `paper/vendor/IEEEtran.cls`

**Modified:**

- `Makefile` — targets `paper`, `paper-artifacts`, `paper-clean`

**Not modified:**

- `results/m510/preserve/` (M5.9 freeze)

## 17. Reproduction command

```bash
make m510-matrix    # matrix regeneration
make m510           # full M5.10 suite (~45s)
make paper          # artifact generation + PDF compile
```

## 18. Current HEAD

```
b0d66661b938ab55075fee650be0bfa55ec5249a
```

Branch: `m6-publication-freeze`

---

## Success criteria checklist

- [x] M5.10 evidence interpretation preserved (RST-A not called vulnerability)
- [x] M5.10 matrix regeneration succeeds
- [x] Claim-to-evidence matrix exists
- [x] Limitations register exists (`results/m6/limitations.md`)
- [x] `paper/main.tex` and all section files exist
- [x] Paper tables compile
- [x] Architecture, reset-ordering, verification workflow figures compile
- [x] `references.bib` exists (minimal verified entries)
- [x] No fabricated citations
- [x] `paper/build/main.pdf` generated
- [x] `paper/CHATGPT_HANDOFF.md` exists
- [x] Bounded results labeled bounded (M57-FP-04, etc.)
- [x] Git commit recorded in provenance macros

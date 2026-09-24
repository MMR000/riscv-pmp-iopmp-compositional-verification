# Final freeze audit — Access-2026-41377

Date: 2026-09-24. Checks run in the public snapshot working tree before commit/tag/push.

## Authoritative sources

| Item | Expected | Observed |
|------|----------|----------|
| RC zip SHA-256 | `67d82af4705cd9f8f19564f6c22ce60cd6e8647bfd561c8f40184d50e240f486` | match (`results/ieee_access_final/packages/`) |
| Cleanup zip SHA-256 | `7a91a075719e73eb4cad35450c737fa594f7b1b1135936015994d4d60ce31d91` | match |
| `rtl/iopmp/iopmp.v` | `dd7fe6a89f22a9c830615528733b2d51ccfb852ca0966d3991ab1172d06c82c8` | match |
| `m7/rtl/m7_research_arbiter.sv` | `204776349008176d2cc2934c0304a27497302cfbe522011ff9358dadf81b4519` | match |

## Integrity commands

| Command | Result |
|---------|--------|
| `python3 scripts/artifact/check_artifact.py` | **PASS** |
| `sha256sum -c results/FROZEN_EVIDENCE_MANIFEST.sha256` | **PASS** (105 paths) |

`check_artifact.py` now also asserts: production RTL hashes; headline J2=277641 / J3=280331 / J3÷J2=+0.97%; IF01-A not current INCONCLUSIVE; README headline not +0.36%.

## Headline consistency

| Check | Result |
|-------|--------|
| README J2 / J3 / +0.97% | PASS |
| `m7_journal_ppa_main.csv` J2/J3 | 277641 / 280331 |
| `m7_full_ibex_ppa_20ns_overhead.csv` J3_vs_J2 area | 0.97 |
| Figure Q1/Q3 data CSVs | 277641 / 280331 / 0.97 |
| IF01-A current matrix `result` | PASS (not INCONCLUSIVE) |
| IF03-C current `err=` | NOT_ISSUED (not empty) |
| Old +0.36% / 279752 / 280749 | historical only (`results/historical/`, `docs/history/`) |

## Manuscript path check

Scanned `paper/**/*.tex` and `paper/**/*.md` for `results/`, `formal/`, `docs/`, `rtl/`, `m7/`, `scripts/` file paths. **Missing: 0**. Paper sources were not edited.

## Formal vs production arbiter

`results/ieee_access_final/arbiter_diff/FORMAL_VS_PRODUCTION_ARBITER.md`: functional body equal after FORMAL-port strip. **No synthesized functional difference.** Not byte-identical.

## Remaining documented inconsistencies (not invented)

See `results/ieee_access_final/REMAINING_INCONSISTENCIES.md`. Includes: this SP-08 rerun used IOPMP `dd7fe6…` (historical SP-08 used `527deba4…`); ARB v2 wall time differs from an earlier host run; SBY `--version` is `unknown SBY version`; PPA extractor `clock_period_ns` field N/A (wrapper period 20.0); C.5 200-seed campaign was not re-run in the cleanup (logs already present).

## Verdict

**Every automated repository integrity check run for this freeze passed.**

# M5.10 reproduction (M6 freeze)

date: 2026-08-11
git_commit: b0d6666
branch: m6-publication-freeze

## make m510-matrix

- exit status: 0
- runtime: ~5s
- log: results/m6/reproduction/m510_matrix.log
- output: results/tables/m510_property_matrix.csv regenerated

## make m510 (full)

- exit status: 0
- runtime: ~45s
- log: results/m6/reproduction/m510_full.log
- includes: m4 formal, m59 bmc, m57 verilator, m55, m56 regressions

## Discrepancies

None observed. M5.10 matrices regenerate successfully.

## Note on FIX-2 m59-bmc

`make m510-formal` may report SBY FAIL for proper ENV-4 due to secondary assert;
primary M57-FP-04 classification remains BOUNDED_EVIDENCE per M5.10 summary.

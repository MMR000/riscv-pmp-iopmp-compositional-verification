# M5.10/M6 baseline regression (M7 start)

date: 2026-08-11
git_commit: b0d66661b938ab55075fee650be0bfa55ec5249a
branch: m7-journal-validation (created from m6-publication-freeze)

## make m510-matrix

- exit status: 0
- runtime: ~0.02s
- log: results/m7/reproduction/m510_matrix.log (regenerated)
- outputs: results/tables/m510_{property,guarantee,assumption_sensitivity}_matrix.csv

## make m510 (full)

- exit status: 0
- runtime: ~42s
- log: results/m7/reproduction/m510_full.log
- includes: m510-formal, m510-matrix, m57-verilator, m55-baseline, m56-regression

## Discrepancies

None observed. M5.10 matrices and regression suite reproduce successfully.

## Note

Prior M6 `make m510` run refreshed formal/sim logs under results/; scientific classifications unchanged per m510_summary.md.

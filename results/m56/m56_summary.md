# M5.6 Summary

- Branch: m56-write-path-fix-formal
- HEAD: ff46d11
- M5.5 commit: ff46d11
- M5.5 tag: checkpoint-m55-write-defect

## Write regression
- Rows: 18, PASS: 16

## Read regression
- Rows: 5, PASS: 5

## Stale-route sequences
- Rows: 6

## Random campaign
- Runs: 500
- Failures: 0

## Evidence index
- Write regression: results/tables/m56_write_regression.csv
- Read regression: results/tables/m56_read_regression.csv
- Timing: results/tables/m56_axi_timing_matrix.csv
- Route freshness: results/tables/m56_route_freshness.csv
- Fix comparison: results/tables/m56_fix_comparison.csv
- Latency: results/tables/m56_latency.csv
- Before CE: results/m56/before_fix/M56-BEFORE-CE.txt
- Patch: patches/iopmp/m56_write_path_transaction_binding.patch
- Formal: results/formal/m56_summary.md

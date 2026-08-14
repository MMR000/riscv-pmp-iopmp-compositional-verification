# Figure QA report

Font: `STIXGeneral`

| ID | PDF | SVG | PNG | approx in (PNG/600) | PNG px | source | bounds | 1-col | labels |
|---|---|---|---|---|---|---|---|---|---|
| Q1 | PASS | PASS | PASS | 3.35×2.10 | 2008×1262 | PASS | PASS | PASS | PASS |
| Q2 | PASS | PASS | PASS | 3.27×2.10 | 1960×1262 | PASS | PASS | PASS | PASS |
| Q3 | PASS | PASS | PASS | 3.15×2.34 | 1888×1405 | PASS | PASS | PASS | PASS |
| Q4 | PASS | PASS | PASS | 2.93×2.52 | 1756×1515 | PASS | PASS | PASS | PASS |
| Q5 | PASS | PASS | PASS | 3.19×2.50 | 1913×1501 | PASS | PASS | PASS | PASS |
| Q6 | PASS | PASS | PASS | 2.81×2.12 | 1684×1271 | PASS | PASS | PASS | PASS |
| Q7 | PASS | PASS | PASS | 3.10×2.24 | 1858×1346 | PASS | PASS | PASS | PASS |
| Q8 | PASS | PASS | PASS | 3.10×2.26 | 1858×1354 | PASS | PASS | PASS | PASS |
| Q9 | PASS | PASS | PASS | 3.19×2.31 | 1913×1388 | PASS | PASS | PASS | PASS |
| Q10 | PASS | PASS | PASS | 3.10×2.03 | 1858×1220 | PASS | PASS | PASS | PASS |
| Q11 | PASS | PASS | PASS | 3.94×2.67 | 2367×1604 | PASS | PASS | PASS | PASS |
| Q12 | PASS | PASS | PASS | 3.11×2.77 | 1865×1660 | PASS | PASS | PASS | PASS |
| Q13 | PASS | PASS | PASS | 3.16×2.45 | 1894×1472 | PASS | PASS | PASS | PASS |
| Q14 | PASS | PASS | PASS | 2.85×2.31 | 1711×1386 | PASS | PASS | PASS | PASS |

## Source-value checks

Q1 areas match `m7_journal_ppa_main.csv` post_route_area at 20 ns.
Q2 cells match the same file `cells` column.
Q3 percentages match `postroute_stdcell_area_um2` rows in the 20 ns overhead CSV.
Q4 MHz match `m7_journal_timing_summary.csv`.
Q7–Q9 match `m7_realcore_performance.csv` / `m7_dma_throughput.csv`.
Q10: 500×7 and 500×0 in `raw_samples.csv`.
Q12: 8×2 early ALLOW on RST-A and DENY on RST-B, all result=PASS.

Scientific-label check: figures avoid 'ASIC measured', 'PMP causes J1 slowdown',
'reset reduces hardware', and collapsing DMA landmarks.

Width uses PNG pixels / 600 dpi after `bbox_inches='tight'`, so it can be slightly
narrower than the 3.5 in canvas. LaTeX includes at `width=\columnwidth`.


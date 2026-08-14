# Official ORFS SKY130HD Ibex full-flow validation

**Result: PASS**

date: 2026-08-12

## Command

```text
cd third_party/OpenROAD-flow-scripts/flow
util/docker_shell make LEC_CHECK=0 DESIGN_CONFIG=./designs/sky130hd/ibex/config.mk
```

Config path (pinned checkout, also present in the image):
`designs/sky130hd/ibex/config.mk`

Official design was **not** modified.

Requested clock period: **10.0 ns** (`designs/sky130hd/ibex/constraint.sdc`)

`SYNTH_HDL_FRONTEND = slang` (built-in Yosys `read_slang`; slang.so plugin not required)

`LEC_CHECK=0` required on this host (same Kepler AVX-512 / i9-14900KF issue as GCD). Does not modify Ibex RTL/config.

## Stage status

| Stage | Status |
|-------|--------|
| synthesis | PASS — slang frontend; `ibex_core` 14065 cells, area 1.29e5 |
| floorplan | PASS (`2_floorplan.odb`) |
| placement | PASS (`3_place.odb`; global place 125 s) |
| CTS | PASS (`4_1_cts.odb`) |
| routing | PASS (`5_2_route.odb`; detailed-route DRC errors **0**) |
| finish / GDS | PASS (`6_final.gds`; no orphan cells) |

## Final timing / DRC (from `logs/6_report.json` and `5_2_route.json`)

| Metric | Value |
|--------|-------|
| requested clock | 10.0 ns |
| post-route setup WNS (worst slack) | +0.0685656 ns |
| post-route setup TNS | 0 |
| post-route hold WNS | +0.42844 ns |
| post-route hold TNS | 0 |
| report_wns (6_finish.rpt) | wns max 0.00 |
| report_tns (6_finish.rpt) | tns max 0.00 |
| fmax (core_clock) | 100.74 MHz |
| detailed-route DRC errors | 0 |
| 5_route_drc.rpt | empty (0 bytes) |
| setup/hold violation count | 0 / 0 |
| utilization | 60.2% |
| finish errors | 0 |

## Runtime

ORFS elapsed-time table **Total 749 s** (~12.5 min). Wrapper wall clock **765 s**.
Dominant step: detailed route `5_2_route` 498 s.

## Layout artifact status

See `layout_artifacts.txt`. GDS/ODB are **not** committed.

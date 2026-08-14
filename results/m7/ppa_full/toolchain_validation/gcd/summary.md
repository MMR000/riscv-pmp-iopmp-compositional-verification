# Official ORFS GCD full-flow validation (nangate45)

**Result: PASS**

date: 2026-08-12

## Command

```text
cd third_party/OpenROAD-flow-scripts/flow
util/docker_shell make LEC_CHECK=0 DESIGN_CONFIG=./designs/nangate45/gcd/config.mk
```

Config path (pinned checkout, also present in the image):
`designs/nangate45/gcd/config.mk`

Requested clock period: **0.46 ns** (`designs/nangate45/gcd/constraint.sdc`)

## LEC_CHECK=0 (required on this host)

Default `LEC_CHECK` is 1 when `kepler-formal` exists in the image.
First run failed at CTS:

```text
Error: cts.tcl, 81 child killed: illegal instruction
```

Diagnosis:
- Host CPU: Intel Core i9-14900KF (AVX-512 fused off; no `avx512*` in `/proc/cpuinfo`)
- Image `kepler-formal` contains AVX-512 (`objdump` count of `%zmm`: 1262)
- OpenROAD binary itself has 0 `%zmm` instructions
- This is the known ORFS Docker AVX-512 issue on 14900K-class CPUs
- Official workaround: `LEC_CHECK=0` (skips Kepler LEC; does **not** modify GCD RTL/config)
- Physical stages still run: synth → floorplan → place → CTS → route → finish/GDS

First-fail log: `flow_lec_default_fail.log`

## Stage status

| Stage | Status |
|-------|--------|
| synthesis | PASS (`1_synth.odb`, 513 cells, area 626.696) |
| floorplan | PASS (`2_floorplan.odb`) |
| placement | PASS (`3_place.odb`) |
| CTS | PASS (`4_1_cts.odb`) with `LEC_CHECK=0` |
| routing | PASS (`5_2_route.odb`; detailed-route DRC errors **0**) |
| finish / GDS | PASS (`6_final.gds` 517K, `6_final.def`, `6_final.odb`) |

## Final timing / DRC (from `logs/6_report.json` and `5_2_route.json`)

| Metric | Value |
|--------|-------|
| setup WNS (worst slack) | +0.016009 ns |
| setup TNS | 0 |
| hold WNS | +0.110785 ns |
| hold TNS | 0 |
| report_wns (6_finish.rpt) | wns max 0.00 |
| report_tns (6_finish.rpt) | tns max 0.00 |
| fmax (core_clock) | 2252.30 MHz |
| detailed-route DRC errors | 0 |
| 5_route_drc.rpt | empty (0 bytes) |
| setup/hold violation count | 0 / 0 |
| utilization | 63.5% |
| instance area | 683.354 um^2 |
| finish errors | 0 |

## Runtime

ORFS elapsed-time table **Total 24 s** (synth/place reused from the first attempt; CTS+route+finish in the `LEC_CHECK=0` rerun).

Wall clock:
- first attempt (fail at CTS): 22 s
- second attempt (`LEC_CHECK=0`, PASS): 16 s
- combined ~38 s

## Layout artifact status

See `layout_artifacts.txt`. `6_final.gds` exists (517K). GDS/ODB are **not** committed.

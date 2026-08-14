# M7 Final Fairness Check (Phase D.3)

**Primary comparison clock:** 20.0 ns (`FLOW_VARIANT=d3_p20p0`)  
**Verdict:** PASS

## Checklist

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Same Ibex commit `c61e11c1e416b9ce2d996013b444c8e558d35b2b` | PASS | pinned third_party/ibex; recorded in 20 ns CSV |
| Same ORFS commit `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c` | PASS | third_party/OpenROAD-flow-scripts |
| Same Docker digest `sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277` | PASS | `run_orfs_m7_docker.sh` / D.3 logs |
| Platform sky130hd | PASS | `m7_common.mk` |
| Same 20 ns primary clock for all J0–J3 | PASS | CLOCK_PERIOD=20.0, ABC_CLOCK_PERIOD_IN_PS=20.0 |
| Memory policy LOGIC-ONLY / MEMORY-BLACKBOX | PASS | PPA wrappers / blackbox mem slaves |
| LEC_CHECK=0 | PASS | identical omission (host no AVX-512 Kepler) |
| Same utilization / floorplan method | PASS | CORE_UTILIZATION=50 |
| Same placement / routing knobs | PASS | PLACE_DENSITY_LB_ADDON=0.25, shared fastroute.tcl, CTS cluster settings |
| Same non-PMP Ibex configuration | PASS | only intended PMPEnable / composition / RST_B differ |
| Equivalent observation-retention methodology | PASS | identical live ports on J0–J3 tops |
| Simulation-only instrumentation excluded | PASS | no sim probes in PPA RTL |
| Expected PMP / IOPMP / reset logic present | PASS | J0 PMP off; J1 PMP on; J2 composition; J3 RST_B + domain reset |

## Validity of 20 ns rows

All of J0–J3 at `d3_p20p0`: GDS YES, DRC 0, setup WNS ≥ 0, setup TNS = 0.

Therefore **20 ns overhead percentages may be called the FINAL main PPA comparison**.

## Explicit non-comparisons (do not mix)

| Evidence type | Role |
|---------------|------|
| 20 ns common | Main area / overhead table |
| 10 ns stress | Which variants close under aggressive target |
| Per-variant Fmax sweep | Demonstrated timing capability |

## Limitations (not fairness failures)

- J4 = NOT_APPLICABLE
- I0/I1 FIX-2 = NOT_RUN
- Power = OMITTED
- FPGA / Smepmp / multi-outstanding DMA / full-Ibex formal = not required for freeze

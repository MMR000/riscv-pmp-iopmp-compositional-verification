# M7 Phase D.2 fairness check (primary 10 ns SKY130HD)

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Same Ibex commit `c61e11c1e416b9ce2d996013b444c8e558d35b2b` | PASS | `phase_d2_start.txt`; wrappers |
| Same ORFS checkout `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c` | PASS | submodule pin |
| Same container digest `sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277` | PASS | digest-pinned runner; no image pull |
| Same SKY130HD platform | PASS | `m7_common.mk` |
| Same fixed 10 ns primary target | PASS | not loosened per variant in primary table |
| Same memory policy LOGIC-ONLY / MEMORY-BLACKBOX | PASS | handshake mem shells |
| Same `LEC_CHECK=0` | PASS | identical omission (Kepler AVX-512) |
| Same optimization / floorplan policy | PASS | util 50, density addon 0.25, ibex CTS/route knobs |
| Same non-PMP Ibex parameters | PASS | `ibex_parameter_comparison.md` |
| Simulation-only logic excluded | PASS | tracer dropped; no C.5 monitors in PPA tops |
| J1 PMP structurally present | PASS | `g_pmp.pmp_i` |
| J2 IOPMP/DMA/arbiter present | PASS | slang + cell increase |
| J3 fail-closed + domain reset present | PASS | `-D RST_B`; `INCLUDE_DOMAIN_RESET=1` |
| Post-route metrics for every variant at 10 ns | FAIL | J1/J3 GRT fail; J2 GDS but setup fail |

## Verdict

**CONDITIONAL_PASS** for a common-target *attempt* and for synth/place overhead under identical 10 ns constraints.

**Not PASS** for a complete four-way post-route area/timing table at 10 ns.

Separate Fmax sweeps (non-primary periods) later obtained post-route PASS for every variant; those periods are **not** interchangeable with the primary 10 ns overhead table.

Primary overhead percentages in `m7_full_ibex_ppa_overhead.csv` use synth and place metrics available for all of J0–J3.

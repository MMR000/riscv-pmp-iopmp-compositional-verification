# M7 J1 Timing Anomaly Audit

**Status:** CAUSE_NOT_DEFINITIVELY_ESTABLISHED  
**Scope:** Explain why demonstrated Fmax(J1) ≪ Fmax(J2/J3) despite J1 having less security logic.  
**Do not invent a single causal story.** Evidence below is observational.

## Demonstrated Fmax (pre–D.3 refine; D.2 freeze)

| Variant | Shortest demonstrated PASS | Demonstrated Fmax |
|---------|---------------------------|-------------------|
| J0 | 9.5 ns | ≈ 105.26 MHz |
| J1 | 16.5 ns | ≈ 60.61 MHz |
| J2 | 12.75 ns | ≈ 78.43 MHz |
| J3 | 13.0 ns | ≈ 76.92 MHz |

J1 refine (D.3): 16.0 ns FAIL; 16.5 / 17 / 18 / 20 ns PASS. Also 10/15 ns GRT congestion FAIL. Repro at 16.5: second run timing/area metrics matched first-run (first-run rule).

## Hypothesis checklist

| ID | Hypothesis | Verdict from evidence |
|----|------------|------------------------|
| A | Genuine PMP critical path | **Not supported as primary.** Worst setup paths at J1 near-limit do **not** name PMP hierarchy. |
| B | J1-specific wrapper structure | **Unlikely.** J0–J3 tops expose identical port lists (29 ports). |
| C | Different observation/live-output ports | **Not supported.** Same observation ports on all variants (`instr_*`, `data_*`, `core_sleep_o`). |
| D | Different core/floorplan size | **Contributing factor.** At 20 ns: J1 core ≈ 4.17e5 µm² vs J2/J3 ≈ 4.82e5 µm² (same CORE_UTILIZATION=50). |
| E | Placement density / congestion | **Strong evidence.** J1 GRT fail at 10/15 ns; higher congestion markers vs J2 at 20 ns. |
| F | Different critical-path endpoints | **Partially.** Near-limit J1/J2/J3 share IF→ALU→`data_req_o`; J0 near-limit is reg2reg. |
| G | Optimization differences from J2/J3 logic | **Plausible.** Same logical path class has very different implemented delay across variants/periods. |
| H | Synthesis/elaboration inconsistency | **No evidence** of wrong PMPEnable / wrong filelist for J1 vs J2/J3. |
| I | ORFS physical stochasticity | **Plausible / contributing.** Period-dependent physical netlists; 20 ns slack order ≠ Fmax order. |

## Observation-port fairness

All four `m7_ppa_j*_top` modules declare the same ports, including unused cfg/DMA/release inputs on J0/J1 (tied off inside `m7_ppa_top`). Live observation assigns are identical:

- `instr_req_o`, `instr_addr_o`
- `data_req_o`, `data_we_o`, `data_addr_o`, `data_err_o`
- `core_sleep_o`

J1 does **not** expose extra PMP-only observability ports relative to J2/J3.  
**No wrapper redesign was applied in D.3** (would require full J0–J3 20 ns rerun).

SDC is shared (`m7/ppa/orfs/sky130hd/constraint.sdc`): 20% period I/O delay on virtual clock `vclk_core_clock` for all variants.

## Critical-path evidence (setup max, non-async)

Source: `6_finish.rpt` worst non-asynchronous max path. Table: `results/tables/m7_critical_paths.csv`.

Near-limit / decisive points:

| Variant | Period | Slack | Arrival | Start | End | Through PMP? |
|---------|--------|-------|---------|-------|-----|--------------|
| J1 | 16.0 FAIL | −0.14 | 14.03 | `if_stage_i.instr_rdata_alu_id_o[*]` | `data_req_o` | **No** |
| J1 | 20.0 PASS | +2.13 | 14.97 | same class | `data_req_o` | **No** |
| J2 | 12.75 PASS | +0.09 | 11.21 | same class | `data_req_o` | **No** |
| J3 | 13.0 PASS | +0.07 | 11.43 | same class | `data_req_o` | **No** |
| J0 | 9.5 PASS | +0.10 | 10.63 | `if_stage` | regfile flop | **No** |

Path hierarchy consistently includes `alu_adder_result_ex` / Han–Carlson adder cells before reaching the observation port.  
**Therefore: do not claim “PMP causes the J1 slowdown” from path evidence.**

Common 20 ns arrivals (same clock, different physical builds):

| Variant | Arrival (ns) | Setup WNS (ns) |
|---------|--------------|----------------|
| J0 | 12.56 | +4.53 |
| J1 | 14.97 | +2.13 |
| J2 | 16.62 | +0.47 |
| J3 | 14.81 | +2.29 |

At the easy common period, **J2 is the tightest**, opposite of the Fmax ordering. This shows period-dependent physical implementation: Fmax cannot be read off 20 ns slack alone.

## Congestion / physical signals

- J1 @ 10 ns and 15 ns: **GRT congestion failure** (no GDS).
- J2 @ 10 ns: GDS OK, setup fail (routable under stress).
- J3 @ 10 ns: GRT congestion failure.
- At 20 ns, log congestion markers (illustrative): J1 ≈ 1.42 / 1.37; J2 ≈ 1.39 / 1.34; J3 ≈ 1.41 / 1.36.

J1’s high-frequency stress behavior is congestion-limited before timing closure is even measurable.

## Floorplan / area context (20 ns common)

| Variant | synth cells | post-route area | core area | buffers | wirelength |
|---------|-------------|-----------------|-----------|---------|------------|
| J0 | 15267 | 157366 | 271002 | 690 | 659360 |
| J1 | 25220 | 241200 | 416927 | 1232 | 1220671 |
| J2 | 28594 | 279752 | 482413 | 1498 | 1338125 |
| J3 | 28130 | 280749 | 482732 | 1510 | 1351910 |

J1 is much larger than J0 (architectural PMP) but smaller than J2/J3. Same utilization target (50%) ⇒ smaller absolute floorplan than J2/J3, which can worsen local congestion on long ALU/IO paths.

## Strongest evidence (ordered)

1. **Critical path is core ALU → observation port `data_req_o`, not PMP/IOPMP** (rules out A as the demonstrated limiter).
2. **J1 fails global route under aggressive periods** where J2 still produces GDS (supports E).
3. **Same path class has ~14 ns arrival on J1@16 ns vs ~11.2 ns on J2@12.75 ns** (supports E/G/I — physical/optimization, not RTL complexity ordering).
4. **20 ns WNS order (J2 tightest) contradicts Fmax order** (supports I / period-dependent PD).
5. **Ports/SDC/observation methodology equivalent** (weakens B/C as explanations).

## What is *not* claimed

- Not claimed: “PMP critical path makes J1 2× slower than J2.”
- Not claimed: unfair J1-only observation fanout (ports match).
- Not claimed: a unique single root cause with full mechanistic proof.

## Classification for the paper

**CAUSE_NOT_DEFINITIVELY_ESTABLISHED.**

Report demonstrated Fmax as an empirical ORFS/sky130hd result. Prefer engineering interpretation:

- Common-period **20 ns** area/overhead as the main PPA comparison.
- Per-variant Fmax as separate capability evidence.
- 10 ns as a high-frequency **stress** point (congestion/timing), not the overhead table.
- J1’s poor Fmax is **consistent with physical congestion / implementation sensitivity** on a shared core→IO path class, **not** with a measured PMP-named critical path.

## Related artifacts

- `results/tables/m7_critical_paths.csv`
- `results/tables/m7_full_ibex_ppa_20ns.csv`
- `results/tables/m7_full_ibex_fmax_sweep.csv`
- `results/m7/ppa_full/orfs/J*/d3_p20p0.log` and D.2 sweep logs
- Finish reports under `third_party/OpenROAD-flow-scripts/flow/reports/sky130hd/m7_j*/`


## Refined J1 Fmax (D.3)

| Period (ns) | Result | Setup WNS |
|-------------|--------|-----------|
| 16.0 | FAIL | −0.14 |
| 16.5 | PASS | +0.065 |
| 17.0 | PASS | +0.116 |
| 18.0 | PASS | +1.252 |
| 20.0 | PASS | +2.129 |

**Shortest demonstrated PASS = 16.5 ns (≈ 60.61 MHz).** Resolution vs nearest FAIL = 0.5 ns.
